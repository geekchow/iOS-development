# 07 · 故障排查、CI 实践与下一步

> 英文原文：[Part 7 — Troubleshooting, CI Recipes & Next Steps](../07-next-steps.md)
>
> **你在哪里：**实用附录。
> **读完本篇你会知道：**如何从第一性原理出发排查任何签名错误，一份 CI 检查清单，几个动手练习，以及延伸阅读去哪里找。

## 缩写对照表

| 缩写 | 英文全称 | 中文 |
|---|---|---|
| CI | Continuous Integration | 持续集成 |
| UDID | Unique Device Identifier | 设备唯一标识 |
| APNs | Apple Push Notification service | Apple 推送通知服务 |
| WWDR | Apple Worldwide Developer Relations | Apple 全球开发者关系（其中间证书） |
| API | Application Programming Interface | 应用程序编程接口 |
| SHA | Secure Hash Algorithm | 安全哈希算法 |
| DTS | Developer Technical Support | （Apple）开发者技术支持 |
| TN | Technical Note | （Apple）技术说明文档 |

## 1. 通用排查方法

每一个签名错误，都是下面这条链上某一环断了。找到断掉的那一环：

```mermaid
flowchart LR
  A[团队状态有效？] --> B[签名身份 = 证书 +<br/>私钥都在钥匙串里？]
  B --> C[描述文件<br/>包含这张证书？]
  C --> D[描述文件的 App ID<br/>与 bundle ID 一致？]
  D --> E[签进去的 entitlements<br/>⊆ 描述文件的？]
  E --> F[设备 UDID 在描述<br/>文件里？/ 开发者模式？]
  F --> G[签名之后<br/>没有改动任何东西？]
  G --> H[没过期 / 没被吊销？]
```

### 能回答几乎所有问题的五条命令
```bash
# 1. Which identities can I actually sign with?
security find-identity -v -p codesigning

# 2. What's in this profile?
security cms -D -i path/to/embedded.mobileprovision | plutil -p -

# 3. Who signed this app, and how?
codesign -dvvv PawPal.app

# 4. What entitlements are sealed in it?
codesign -d --entitlements - --xml PawPal.app | plutil -p -

# 5. Is the signature intact?
codesign --verify --deep --strict --verbose=4 PawPal.app
```

## 2. 报错 → 原因 → 解决

| 报错（Xcode / 设备 / CI） | 断掉的环 | 解决办法 |
|---|---|---|
| *No signing certificate "iOS Development" found* | B | 创建一张证书，或导入带私钥的 `.p12` |
| *Provisioning profile "X" doesn't include signing certificate "Y"* | C | 重新生成包含你证书的描述文件，或改用匹配的签名身份 |
| *No profiles for 'com.x.y' were found* | D | 创建 App ID 和描述文件；开启自动签名或 `-allowProvisioningUpdates` |
| *Provisioning profile doesn't include the aps-environment entitlement* | E | 在 App ID 上开启该能力 → 重新生成描述文件 |
| *Unable to install … integrity could not be verified* | F / E | 添加 UDID、重新生成、重新导出；小组件/扩展的描述文件也要检查 |
| 开发版在 iOS 16+ 上打不开 | F | 打开开发者模式 |
| *errSecInternalComponent*（CI） | B | 解锁钥匙串；执行 `security set-key-partition-list -S apple-tool:,apple: …` |
| *a sealed resource is missing or invalid* | G | 签名之后有东西动了应用包；重新签名，或者别让构建后脚本修改它 |
| *resource fork, Finder information, or similar detritus not allowed* | G | 签名前执行 `xattr -cr PawPal.app` |
| Mac 上证书显示「不受信任」 | B（证书链） | 安装当前版本的 Apple WWDR 中间证书 |
| 调试版推送正常、TestFlight 不行（或反过来） | E | 服务器用的 APNs 环境和 `aps-environment` 不一致 |
| 企业版应用：*Untrusted Developer* | F | 在 设置 → 通用 → VPN 与设备管理 里信任它 |
| Ad Hoc 应用一年后突然打不开 | H | 描述文件/证书过期；重新生成并重新分发 |

## 3. CI 检查清单

- [ ] 使用 **App Store Connect API 密钥**（`.p8`、Key ID、Issuer ID），存为 CI 的密钥，永远不要用个人 Apple ID。
- [ ] 选定一种策略并坚持下去：
  - **自动签名 + API 密钥 + 云端托管证书：**`xcodebuild -allowProvisioningUpdates -authenticationKey…`。维护成本最低。
  - **手动管理共享资产**（比如 *fastlane match*）：加密后的证书和描述文件放在私有仓库或存储桶里，CI 上只读。结果确定，很适合团队。
- [ ] 如果要导入 `.p12`：创建一个**临时钥匙串**，解锁，设置超时，执行 `set-key-partition-list`，加入搜索列表，并在**构建结束后删掉它**。
- [ ] 在 `ExportOptions.plist` 里按 bundle ID 固定每一份描述文件，包括每一个扩展。
- [ ] 跟踪到期时间：在分发证书和 Ad Hoc/企业描述文件到期前 30 天发出提醒。
- [ ] 永远不要把未加密的 `.p12`、`.p8` 或 `.mobileprovision` 文件提交进仓库。

## 4. 练习

1. **解剖一份描述文件。** 从 `~/Library/Developer/Xcode/UserData/Provisioning Profiles/` 里解码一份，取出 `DeveloperCertificates.0`，把它的 SHA-1 和 `security find-identity` 的输出比对。
2. **故意破坏一个签名。** 为真机构建 PawPal，修改 `.app` 里的一张 PNG，运行 `codesign --verify`。然后用 `codesign --force --sign <identity> --entitlements …` 重新签名，再校验一次。
3. **entitlement 子集测试。** 在 `.entitlements` 里加一个 App ID 没有开启的 entitlement，记下 Xcode 给出的确切报错，以及是哪一环（E）断了。
4. **Ad Hoc 设备测试。** 导出一个 Ad Hoc 版本，查看 `ProvisionedDevices`，在动手安装之前预测哪些设备能装上。
5. **比较 Authority 证书链。** 对你的开发版，以及一个从 Mac App Store 安装的应用（`/Applications/*.app`）分别运行 `codesign -dvv`，比较 `Authority=` 那几行。
6. **macOS 公证。** 用 Developer ID + `--options runtime` 给一个很小的 Mac 应用签名，用 `notarytool` 公证、钉上票据，再用 `spctl -a -vv` 检查。

## 5. 延伸阅读

- Apple：*Code Signing Guide*（已归档）、*TN3125: Inside Code Signing: Provisioning Profiles*、*TN3126: Inside Code Signing: Hashes*、*TN3127: Inside Code Signing: Requirements*、*TN2206: macOS Code Signing In Depth*。
- Apple Platform Security Guide：*App code signing process*、*Runtime process security* 这两节。
- Apple 开发者文档：*Distributing your app for beta testing and releases*、*Notarizing macOS software before distribution*、*Enabling Developer Mode on a device*。
- App Store Connect API：*Provisioning* 相关端点（Certificates、Profiles、Devices、Bundle IDs）。
- Apple 开发者论坛的 Code Signing 标签。Apple DTS（Developer Technical Support，开发者技术支持）工程师会在那里发很详细的解释。

---
← [06 · 完整演练](06-walkthrough.md) · [00 · 系列导读](00-overview.md) · [概念全景图](03-concept-map.md)
