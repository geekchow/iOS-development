# 04 · 贯穿示例：LaunchLab

> 英文原文：[Part 4 — The Running Example: LaunchLab](../04-running-example.md)
>
> **你在哪里：**第四阶段，整个系列的主线。
> **读完本篇你会知道：**示例应用长什么样，以及一次启动故事的浅层追踪。后面每一篇深入专题都会回到这里编号的步骤。

## 缩写对照表

| 缩写 | 英文全称 | 中文 |
|---|---|---|
| UI | User Interface | 用户界面 |
| VC | View Controller | 视图控制器 |
| URL | Uniform Resource Locator | 统一资源定位符 |
| dyld | Dynamic Link Editor | 动态链接器 |
| UIKit | User Interface Kit | Apple 的 UI 框架 |

## 三句话介绍这个应用

**LaunchLab** 是一个小型 UIKit 应用（代码在 [`sample/`，英文](../sample/README.md)），它会记录每一个启动和生命周期回调，时间戳从进程创建那一刻起算。第一次启动时它显示一个**新手引导（Onboarding）**页面；点击 *Get started* 后切换到主界面：一个**标签栏（tab bar）**，里面有记录事件的 *Timeline*，以及用来做导航实验的 *Lifecycle Lab*。它还能响应 URL `launchlab://lab`。

## 故事

**Sam** 安装了 LaunchLab，打开它，走完新手引导，切到另一个应用，再切回来，之后又在「备忘录」里点了一个 `launchlab://lab` 链接。

### 第 1 步：点击 → 进程
Sam 点击图标。**系统**显示**启动屏**（来自 Info.plist 里的 `UILaunchScreen`），创建一个**进程**，然后 **dyld** 加载 LaunchLab 的二进制和 UIKit。

### 第 2 步：main
**`main()`** 开始运行（LaunchLab 在 `main.swift` 里把它显式写了出来）。它记录一条 `"main() entered"`，然后调用 **`UIApplicationMain`**。

### 第 3 步：UIApplication + AppDelegate
`UIApplicationMain` 创建 **`UIApplication`** 单例和 **AppDelegate**，读取 Info.plist，启动 **run loop**，接着调用 `willFinishLaunchingWithOptions` 和 `didFinishLaunchingWithOptions`。LaunchLab 在这里配置全局服务。

### 第 4 步：请求一个场景
系统需要一个 UI，于是创建一个**场景会话（scene session）**，并询问 AppDelegate 的 `configurationForConnecting`。LaunchLab 返回 `"Default Configuration"`，Info.plist 把它映射到 `SceneDelegate`。

### 第 5 步：SceneDelegate 构建窗口
UIKit 创建 **`UIWindowScene`** 和 **SceneDelegate**，然后调用 `scene(_:willConnectTo:options:)`。LaunchLab 创建一个 **`UIWindow`**，向 `RootRouter` 要一个**根视图控制器**（因为是第一次启动，所以是新手引导页），再调用 `makeKeyAndVisible()`。

### 第 6 步：第一个视图控制器加载并出现
窗口需要根视图控制器的视图，于是 `OnboardingViewController` 依次收到 `loadView` → `viewDidLoad`。场景进入前台（`sceneWillEnterForeground`），视图控制器收到 `viewWillAppear` → `viewIsAppearing` → 布局，场景变为活跃（`sceneDidBecomeActive`），视图控制器再收到 `viewDidAppear`。**第一帧**画出来，启动屏消失。**启动完成。**

### 第 7 步：替换根视图控制器
Sam 点击 *Get started*。`RootRouter` 把 `window.rootViewController` 换成一个 `UITabBarController`，里面装着两个 `UINavigationController`。新手引导页收到 `viewWillDisappear`/`viewDidDisappear` 后被释放；Timeline 页面收到 `viewDidLoad` 和各个出现回调。

### 第 8 步：进入后台再回来
Sam 上滑回到主屏幕：`sceneWillResignActive` → `sceneDidEnterBackground`。Sam 回到应用：`sceneWillEnterForeground` → `sceneDidBecomeActive`。**Timeline 视图控制器的 `viewWillAppear` 不会触发**，因为它在视图层级里的位置从来没有变过。

### 第 9 步：深度链接
- **热启动**（应用在后台）：Sam 点击 `launchlab://lab`，场景收到 `scene(_:openURLContexts:)`，于是切换到 *Lifecycle Lab* 标签页。
- **冷启动**（Sam 事先强制退出了应用）：第 1–5 步重新跑一遍，这一次 URL 出现在 `willConnectTo` 的 `connectionOptions.urlContexts` 里。`openURLContexts` *不会*被调用。

### 第 10 步：Lifecycle Lab
Sam 推入一个详情页，弹出一个 sheet，再弹出一个全屏模态页。Timeline 显示：**sheet** 不会让下面的页面「消失」，**全屏**模态则会。

## 每篇深入专题覆盖哪些步骤

| 深入专题 | 步骤 |
|---|---|
| 5.1 进程启动与 main | 1、2 |
| 5.2 UIApplication 与 AppDelegate | 3、4 |
| 5.3 UIScene 与 SceneDelegate | 4、5、8、9 |
| 5.4 UIWindow 与根视图控制器 | 5、7、9 |
| 5.5 视图控制器生命周期 | 6、7、8、10 |
| 5.6 闭包实战 | 7 |

[交互式演示（英文）](../demo/launch-sequence.html)会按泳道逐步播放第 1–10 步的动画。

---
← [03 · 概念地图](03-concept-map.md) · 下一篇 → [05.1 · 进程启动与 main](05-deep-dives/01-process-launch-and-main.md)
