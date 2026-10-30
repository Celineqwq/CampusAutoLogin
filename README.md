# Campus Auto Login - 校园网自动登录脚本

针对 Dr.COM / ePortal 认证系统的校园网自动登录 PowerShell 脚本。

## 功能

- 自动检测网络状态（通过访问 baidu.com 判断是否被重定向到认证页面）
- 提取 portal 的 queryString
- 调用 pageInfo / getServices 获取服务信息
- 自动提交登录
- 登录成功后弹出通知
- 支持静默运行（通过 VBS 启动器）

## 使用方法

### 1. 配置凭据

复制 `config.example.ps1` 为 `config.ps1`，填入你的学号和密码：

```powershell
$Username = '你的学号'
$Password = '你的密码'
```

### 2. 运行

**方式一：直接运行 PowerShell**
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File CampusAutoLogin.ps1
```

**方式二：静默运行（无窗口）**
双击 `CampusAutoLogin.vbs` 或通过任务计划程序调用。

### 3. 设置开机自启（可选）

通过 Windows 任务计划程序：
- 触发器：登录时
- 操作：启动 `CampusAutoLogin.vbs`
- 或设置间隔重复运行（如每 5 分钟检查一次网络状态）

## 文件结构

```
CampusAutoLogin/
├── CampusAutoLogin.ps1    # 主脚本
├── CampusAutoLogin.vbs    # 静默启动器
├── config.example.ps1     # 配置模板
├── config.ps1             # 个人配置（已加入 .gitignore）
└── README.md
```

## 工作原理

1. 访问 `http://www.baidu.com`，检测是否被 302 重定向到认证 portal
2. 若已在线，直接退出
3. 若被重定向，从重定向 URL 中提取 `queryString`
4. 调用 portal 的 `pageInfo` 和 `getServices` 接口获取服务列表
5. 提交登录请求（`userId`, `password`, `service`, `queryString`）
6. 验证网络是否真正连通

## 依赖

- Windows 系统（PowerShell）
- 网络连接到校园网

## 免责声明

本脚本仅供学习和个人使用。

- 使用者应遵守所在校园网的**使用规定和法律法规**
- 请勿将本脚本用于任何非法用途或商业用途
- 作者不对因使用本脚本而产生的任何问题或损失承担责任
- 使用本脚本即表示您同意自行承担所有风险

## 许可

MIT
