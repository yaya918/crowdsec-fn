# CrowdSec 安装脚本修复说明

## 问题描述

原安装脚本在配置 rsyslog 时存在重复配置问题：

1. 在 `/etc/rsyslog.conf` 末尾添加 `auth,authpriv.*` 配置
2. 同时在 `/etc/rsyslog.d/99-crowdsec-ssh.conf` 中也添加了 `auth,authpriv.*` 配置

这导致每条 SSH 认证日志被记录 4 次（systemd journal 发送 2 条，rsyslog 重复配置导致再翻倍），使得用户输错 2-3 次密码就被误判为暴力破解。

## 修复内容

### 1. 修改 rsyslog 配置逻辑

**修改位置**: `install_callback` 第 115-145 行

**修改前**:
- 在 `/etc/rsyslog.conf` 中添加 `auth,authpriv.*` 配置
- 创建 `/etc/rsyslog.d/99-crowdsec-ssh.conf` 并添加相同配置

**修改后**:
- 删除 `/etc/rsyslog.conf` 中的重复配置
- 删除旧的 `/etc/rsyslog.d/99-crowdsec-ssh.conf`
- 只创建 `/etc/rsyslog.d/50-crowdsec.conf`，使用简洁配置：
  ```conf
  # CrowdSec: 确保 SSH 认证日志记录到 auth.log
  auth,authpriv.*                  /var/log/auth.log
  ```

### 2. 添加自定义 SSH 规则

**修改位置**: `install_callback` 第 508-545 行

**新增功能**:
- 自动创建自定义 `ssh-bf-custom.yaml` 规则
  - 容量从 5 提升到 12（适应日志重复）
  - 时间窗口: 10 秒
  
- 自动创建自定义 `ssh-slow-bf-custom.yaml` 规则
  - 容量从 10 提升到 20
  - 时间窗口: 60 秒

- 自动禁用默认的 `ssh-bf` 和 `ssh-slow-bf` 规则

## 效果

修复后：
- ✅ rsyslog 配置不再重复
- ✅ SSH 登录失败日志只记录一次（或两次，取决于 systemd journal）
- ✅ 用户可以输错 3 次密码而不会被误封
- ✅ 仍然保持对真实暴力破解的有效防护

## 测试验证

修复后的阈值：
- **快速暴力破解**: 10 秒内失败 12 次才触发封禁（原来 5 次）
- **慢速暴力破解**: 60 秒内失败 20 次才触发封禁（原来 10 次）

假设日志有 2 倍重复：
- 快速规则: 实际需要 6 次失败触发
- 慢速规则: 实际需要 10 次失败触发

## 注意事项

1. 如果系统中已存在旧的配置，首次安装时会自动清理
2. 自定义规则文件位于: `/vol1/@appshare/crowdsec/crowdsec/scenarios/`
3. 如需调整阈值，可直接修改自定义规则文件后重启 CrowdSec

## 相关文件

- `/vol1/1000/yaya/fn-app/fn-app/crowdsec-fn/cmd/install_callback` - 主安装脚本
- `/etc/rsyslog.d/50-crowdsec.conf` - rsyslog 配置
- `/vol1/@appshare/crowdsec/crowdsec/scenarios/ssh-bf-custom.yaml` - 自定义 SSH 快速暴力破解规则
- `/vol1/@appshare/crowdsec/crowdsec/scenarios/ssh-slow-bf-custom.yaml` - 自定义 SSH 慢速暴力破解规则
