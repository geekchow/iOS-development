# 04 · 贯穿示例：发布 PawPal

> 英文原文：[Part 4 — The Running Example: Shipping PawPal](../04-running-example.md)
>
> **你在哪里：**第四阶段，整个系列的主线。
> **读完本篇你会知道：**一个贴近真实的场景，这里只浅浅走一遍，后面每篇深入专题都会回到它。请按编号记住这些步骤，后面的文章会直接引用（「回想第 5 步……」）。

## 缩写对照表

| 缩写 | 英文全称 | 中文 |
|---|---|---|
| CI | Continuous Integration | 持续集成 |
| UDID | Unique Device Identifier | 设备唯一标识 |
| CSR | Certificate Signing Request | 证书签名请求 |
| APNs | Apple Push Notification service | Apple 推送通知服务 |
| AMFI | Apple Mobile File Integrity | Apple 移动文件完整性（内核扩展） |
| API | Application Programming Interface | 应用程序编程接口 |
| IPA | iOS App Store Package | iOS 安装包 |

## 三句话说清场景

**Mia** 是一名独立开发者，正在开发 **PawPal**：一个 iOS 应用，用**推送通知**提醒宠物主人带宠物去看兽医，并通过 **App Group** 和主屏幕小组件共享数据。她先在自己的 iPhone 上调试，再把测试版发给朋友 **Leo** 的 iPhone，最后通过 **TestFlight** 和 **App Store** 发布给所有人。一路上她还搭了 **CI**（Continuous Integration，持续集成），并踩了两个经典的坑。

## 后面会反复用到的固定事实

| 项目 | 值 |
|---|---|
| 团队 | 「Mia Chen」（个人），**Team ID `7XQ4K9P2LM`** |
| Bundle ID | `com.miachen.pawpal` |
| App ID | `7XQ4K9P2LM.com.miachen.pawpal` |
| 小组件扩展的 bundle ID | `com.miachen.pawpal.widget` |
| App Group | `group.com.miachen.pawpal` |
| Mia 的 iPhone UDID | `00008110-001A2B3C4D5E801E` |
| Leo 的 iPhone UDID | `00008120-000F1E2D3C4B5A6E` |

## 浅浅走一遍整个旅程

每个概念和组件第一次出现时都用**粗体**标出。

### 第 1 步：加入开发者计划
Mia 以个人身份加入 **Apple 开发者计划**并支付年费。Apple 为她创建了一个**团队**，Team ID 是 `7XQ4K9P2LM`，她是**账号持有人（Account Holder）**。

### 第 2 步：拿到开发证书
她在 Xcode → Settings → Accounts 里登录。开启自动签名后，Xcode 让她的**钥匙串**生成一把**私钥**和一个 CSR（Certificate Signing Request，证书签名请求），发送给**开发者门户**，并拿回一张 **Apple Development 证书**。钥匙串把两者配对成一个**签名身份**：`Apple Development: Mia Chen (R8J2N5T7QX)`。

### 第 3 步：注册 App ID 并开启能力
她创建了 **App ID** `7XQ4K9P2LM.com.miachen.pawpal`，开启 **Push Notifications** 和 **App Groups** 两项**能力**。在 Xcode 里，这会生成一个 `PawPal.entitlements` 文件，里面有 `aps-environment`、`com.apple.security.application-groups` 这样的 **entitlements**。

### 第 4 步：注册她的 iPhone
她把 iPhone 连上电脑。Xcode 读出 **UDID**（Unique Device Identifier，设备唯一标识），把它注册为团队名下的一台**设备**。

### 第 5 步：拿到开发用描述文件
门户生成一份 **iOS App Development 描述文件**，上面列着：她的开发证书、App ID、允许的 entitlements（`aps-environment = development`、`get-task-allow = true`、App Group……）、她 iPhone 的 UDID，以及到期日。Apple 为它签名。

### 第 6 步：构建并签名
**Xcode** 编译 PawPal 和小组件，把描述文件以 `embedded.mobileprovision` 的名字复制进应用包，然后运行 **`codesign`**，在每个二进制里写入**代码签名**（CodeDirectory 里的逐页哈希，由她的私钥签名）。先签小组件，最后签主应用。

### 第 7 步：在她的 iPhone 上安装运行
**installd** 检查描述文件：是 Apple 签的吗？过期了没有？列了她的 UDID 吗？列了签名证书吗？entitlements 在允许范围内吗？启动时，**AMFI** 和**内核**再检查代码签名，以及每个被加载的内存页。PawPal 跑起来了，调试器也能附加上去（多亏了 `get-task-allow`），她还从 *sandbox* 环境的 APNs（Apple Push Notification service，Apple 推送通知服务）拿到了推送令牌。

### 第 8 步：给 Leo 打一个 Ad Hoc 包 *（失败 #1）*
Mia 导出一个 **Ad Hoc** 包，用 AirDrop 把 `.ipa` 发给 Leo，结果**装不上**：Leo 的 UDID 不在描述文件里。她注册了 Leo 的 UDID，重新生成 **Ad Hoc 描述文件**（用她的 **Apple Distribution 证书**签名），再导出一次，这回装上了。

### 第 9 步：上传 App Store Connect，走 TestFlight 和审核
她用一份 **App Store** 分发描述文件（没有设备列表）归档，上传到 **App Store Connect**，由 Apple 处理这个构建。外部测试者通过 **TestFlight** 安装。通过 **App Review** 之后，Apple 用自己的密钥给应用**重签名**并上架。

### 第 10 步：CI 崩了 *（失败 #2）*
Mia 把构建挪到一台 CI 用的 Mac 上。第一次运行就失败了，报 `errSecInternalComponent` / *「No signing certificate 'iOS Distribution' found」*：CI 机器上有描述文件，但**没有私钥**。她把一个 `.p12` 导入一个临时解锁的钥匙串，问题解决（另一种办法是改用**云端托管证书**加 **App Store Connect API 密钥**）。

### 第 11 步：一年以后
她的分发证书过期了。App Store 上的版本照常可用，因为 Apple 已经重签过名；Leo 手上的 Ad Hoc 版本却打不开了，因为它的描述文件过期了。

## 每篇深入专题对应哪些步骤

| 深入专题 | PawPal 步骤 |
|---|---|
| 5.1 开发者账号与团队 | 1、10（角色、API 密钥） |
| 5.2 签名证书 | 2、8、10、11 |
| 5.3 App ID 与 entitlements | 3、6、7 |
| 5.4 设备 | 4、8 |
| 5.5 描述文件 | 5、8、9、11 |
| 5.6 codesign | 6 |
| 5.7 设备端校验 | 7、8、11 |
| 5.8 分发与重签名 | 8、9、11 |

---
← [03 · 概念全景图](03-concept-map.md) · 下一篇 → [5.1 · 开发者账号与团队（英文）](../05-deep-dives/01-developer-account-and-team.md)
