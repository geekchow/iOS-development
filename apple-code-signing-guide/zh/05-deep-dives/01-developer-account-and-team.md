# 05.1 · 开发者账号与团队

> 英文原文：[5.1 — The Developer Account & Team](../../05-deep-dives/01-developer-account-and-team.md)
>
> **你在哪里：**第一篇深入专题，身份的根。
> **读完本篇你会知道：**团队（Team）到底是什么，几种开发者计划有什么区别，角色如何限制谁能创建签名资产，以及团队如何为自动化流程做身份认证。

## 缩写对照表

| 缩写 | 英文全称 | 中文 |
|---|---|---|
| D-U-N-S | Data Universal Numbering System | 邓白氏编码（企业唯一标识） |
| CI | Continuous Integration | 持续集成 |
| 2FA | Two-Factor Authentication | 双重认证 |
| API | Application Programming Interface | 应用程序编程接口 |
| EC | Elliptic Curve | 椭圆曲线（密码学） |
| JWT | JSON Web Token | JSON 网络令牌 |
| APNs | Apple Push Notification service | Apple 推送通知服务 |

## 角色回顾
**负责：**站在每一张证书、每一个 App ID、每一台设备、每一份描述文件背后的那个在法律上可问责的身份。**出现在 PawPal 的哪些步骤：**1（加入计划）、10（CI 通过 API 密钥访问）。

## 内部设计

### Apple ID 与团队
- **Apple ID** 是*个人*的登录账号。
- **团队（Team）**是拥有签名资产的*实体*。一个 Apple ID 可以属于多个团队。Xcode 里「Team」下拉框中的每一项都是一个团队，而不是一个人。
- **Team ID** 是一个 10 位字母数字组成的字符串（比如 `7XQ4K9P2LM`），它会出现在：
  - 证书主题里（`OU=7XQ4K9P2LM`）；
  - App ID 前缀里（`7XQ4K9P2LM.com.miachen.pawpal`）；
  - entitlements 里（`com.apple.developer.team-identifier`、`application-identifier`）；
  - 钥匙串访问组里，所以只有同一个团队的两个应用才能共享钥匙串条目。

因为 Team ID 最终会被封进经过密码学保护的数据里，**你没法在不改变应用身份的前提下，把它的签名身份挪到另一个团队**。也正因为如此，团队之间转移应用需要走一套由 Apple 主导的正式流程。

### 计划类型

| 计划 | 适用对象 | 能做什么 | 说明 |
|---|---|---|---|
| **免费（个人团队，Personal Team）** | 在 Xcode 里登录的任意 Apple ID | 只能在设备上开发 | 描述文件 **7 天**过期；设备和 App ID 数量限制很小；很多能力（推送等）用不了；不能分发 |
| **Apple 开发者计划：个人** | 个人 | 完整的开发能力 + App Store / TestFlight / Ad Hoc + Developer ID（macOS） | 卖家名称就是你的法定姓名 |
| **Apple 开发者计划：组织** | 法律实体（需要 D-U-N-S 编码） | 同上，另外支持多名成员和角色 | 卖家名称是公司名 |
| **Apple 企业开发者计划** | 经 Apple 批准的大型组织 | 不经 App Store、也不需要设备列表，直接**内部（In-House）**分发给员工 | 监管很严；一旦滥用，证书会被吊销，所有已安装的应用同时失效 |

### 角色：谁能创建签名资产
在组织团队里，App Store Connect 的角色决定了谁能操作 Certificates, Identifiers & Profiles 这一部分。简化后如下：

| 角色 | 能创建开发证书 | 能创建分发证书 | 能注册设备 / App ID / 描述文件 |
|---|---|---|---|
| Account Holder（账号持有人） | ✅ | ✅ | ✅ |
| Admin（管理员） | ✅ | ✅ | ✅ |
| App Manager / Developer | ✅（自己的） | 仅在被授予「Access to Certificates, Identifiers & Profiles」时 | 未经授权则受限 |
| Marketing / Sales / Finance | ❌ | ❌ | ❌ |

设计思路是：**开发身份是个人的、廉价的；分发身份是共享的、严加看管的。**每个工程师都有自己的 Apple Development 证书，但能签发 Apple Distribution 证书的人应该极少。

### 自动化流程的身份认证：App Store Connect API 密钥
在 CI 机器上用一个真人的 Apple ID 加双重认证（2FA，Two-Factor Authentication）登录是行不通的。Apple 给出的答案是 **App Store Connect API 密钥**：

- 在 App Store Connect → Users and Access → Integrations 里创建；
- 只能下载*一次*，是一个 `.p8` 文件（一把 EC，即椭圆曲线私钥），同时会给出 **Key ID** 和 **Issuer ID**；
- 用来签发短期有效的 **JWT**（JSON Web Token），为 API 调用做认证，包括那些和签名资产相关的端点（证书、描述文件、设备、bundle ID）。

`xcodebuild` 可以直接使用这些参数：

```bash
xcodebuild -allowProvisioningUpdates \
  -authenticationKeyPath ~/keys/AuthKey_ABC123XYZ.p8 \
  -authenticationKeyID ABC123XYZ \
  -authenticationKeyIssuerID 69a6de7e-xxxx-xxxx-xxxx-5bc37c11a4d1 \
  -scheme PawPal archive
```

别把这个 `.p8` 和 **APNs 认证密钥**（也是 `.p8`）搞混了。后者用来让你的*服务器*向 APNs（Apple Push Notification service，Apple 推送通知服务）证明身份，和代码签名毫无关系。

## 与其他部件的交互
- **→ 门户：**Certificates, Identifiers & Profiles 里的每一条记录，所有者都是团队。
- **→ 证书：**每张证书的主题里都带着 Team ID，证书是否有效也取决于会员资格是否有效。
- **→ App Store Connect：**团队必须先接受相关协议（付费应用协议等），上传才能成功。

## ⚓ 回到示例
- **第 1 步。** Mia 以*个人*身份加入计划，Apple 分配给她 Team ID `7XQ4K9P2LM`。她是账号持有人，可以签发任何类型的证书。如果她只用免费的个人团队，第 5 步的描述文件会每 7 天过期一次，第 3 步的推送能力也根本用不了。
- **第 10 步。** 为了 CI，她创建了一个 *App Manager* 角色的 App Store Connect API 密钥（如果 CI 需要创建分发证书，就要用 *Admin*），并把 `.p8` 存为 CI 的密钥。CI 自始至终接触不到她的 Apple ID 密码。

## 失败时的表现
| 情况 | 后果 |
|---|---|
| **会员资格失效**（没续费） | 已上架的应用会被下架；不能再创建新的证书或描述文件，已有的分发描述文件也会失效 |
| **没有接受协议** | 上传和 TestFlight 会报协议相关的错误，虽然签名本身没有任何问题 |
| **账号因滥用被终止** | Apple 吊销该团队的证书；设备一旦得知吊销，企业版和 Ad Hoc 版本就无法启动 |
| **API 密钥泄露** | 立刻在 App Store Connect 里吊销它。密钥无法重新下载，所以要像对待密码一样对待 `.p8` |

---
← [04 · 贯穿示例](../04-running-example.md) · 下一篇 → [05.2 · 签名证书与私钥](02-signing-certificates.md) · [概念全景图](../03-concept-map.md)
