# CrowdSec 家用NAS场景规则配置说明

## 概述

本配置为飞牛OS的CrowdSec应用提供了专门优化的家用NAS安全检测规则。这些规则旨在保护家庭NAS系统免受常见的网络攻击，同时尽量减少误报。

## 已安装的场景规则

### 核心安全规则

#### SSH安全防护
- `crowdsecurity/ssh-bf` - SSH暴力破解检测
- `crowdsecurity/ssh-slow-bf` - SSH慢速暴力破解检测
- `crowdsecurity/ssh-empty-password` - 空密码检测
- `crowdsecurity/ssh-connection-attempts` - 异常连接尝试
- `crowdsecurity/ssh-slow-dos` - SSH慢速DoS攻击

#### Web服务器防护 (Nginx/Apache)
- `crowdsecurity/nginx` - Nginx服务器完整防护规则集
- `crowdsecurity/apache2` - Apache服务器完整防护规则集
- `crowdsecurity/http-probing` - HTTP探测攻击检测
- `crowdsecurity/http-crawl-non-statics` - 恶意爬虫检测
- `crowdsecurity/http-bad-user-agent` - 恶意User-Agent检测
- `crowdsecurity/http-sqli` - SQL注入攻击检测
- `crowdsecurity/http-xss` - XSS攻击检测
- `crowdsecurity/http-path-traversal` - 路径遍历攻击检测
- `crowdsecurity/http-robots-txt` - Robots.txt违规检测
- `crowdsecurity/http-scan` - 网络扫描检测
- `crowdsecurity/http-dos` - HTTP DoS攻击检测
- `crowdsecurity/http-backdoor-attempts` - 后门尝试检测
- `crowdsecurity/http-404` - 异常404错误检测
- `crowdsecurity/http-404-aggressive` - 激进404扫描检测
- `crowdsecurity/http-generic-bf` - 通用暴力破解检测
- `crowdsecurity/http-generic-bruteforce` - 通用暴力破解检测

#### 系统安全
- `crowdsecurity/linux` - Linux系统安全规则
- `crowdsecurity/whitelists` - IP白名单管理

#### 文件传输服务
- `crowdsecurity/vsftpd` - vsftpd FTP服务器防护
- `crowdsecurity/proftpd` - ProFTPD FTP服务器防护
- `crowdsecurity/smb` - Samba/CIFS文件共享防护

### 规则集合

以下集合会自动安装相关的解析器和场景规则：

- `crowdsecurity/sshd` - SSH服务完整规则集
- `crowdsecurity/nginx` - Nginx完整规则集
- `crowdsecurity/apache2` - Apache完整规则集
- `crowdsecurity/linux` - Linux系统完整规则集
- `crowdsecurity/base-http` - HTTP基础规则集

## 日志采集配置

安装脚本会自动创建以下日志采集配置文件：

### 配置文件位置
- 配置目录: `/vol1/@appshare/crowdsec/crowdsec/`
- 采集配置: `/vol1/@appshare/crowdsec/acquis.d/`

### 自动创建的采集配置

#### SSH日志 (`ssh.yaml`)
- `/var/log/auth.log` (Debian/Ubuntu)
- `/var/log/secure` (RHEL/CentOS)
- `/var/log/messages` (其他系统)

#### Nginx日志 (`nginx.yaml`)
- `/var/log/nginx/access.log`
- `/var/log/nginx/error.log`
- `/var/log/nginx/*.log`

#### Apache日志 (`apache2.yaml`)
- `/var/log/apache2/access.log`
- `/var/log/apache2/error.log`
- `/var/log/httpd/access_log` (RHEL/CentOS)
- `/var/log/httpd/error_log`

#### 系统日志 (`syslog.yaml`)
- `/var/log/syslog` (Debian/Ubuntu)
- `/var/log/kern.log`
- `/var/log/messages` (RHEL/CentOS)

#### FTP日志 (`ftp.yaml`)
- `/var/log/vsftpd.log`
- `/var/log/proftpd/access.log`

#### SMB日志 (`smb.yaml`)
- `/var/log/samba/*.log`

## 决策配置

### 默认封禁策略

| 攻击类型 | 封禁时长 | 说明 |
|---------|---------|------|
| 一般攻击 | 4小时 | 默认IP阻止 |
| SSH暴力破解 | 24小时 | SSH相关的暴力破解攻击 |
| SQL注入 | 48小时 | 数据库注入攻击 |
| XSS攻击 | 24小时 | 跨站脚本攻击 |
| 网络扫描 | 12小时 | 端口扫描和探测 |

### 白名单配置

以下IP地址范围会被自动添加到白名单，不会被阻止：

- `127.0.0.0/8` - 本地回环地址
- `::1/128` - IPv6本地回环
- `10.0.0.0/8` - 私有网络A类
- `172.16.0.0/12` - 私有网络B类
- `192.168.0.0/16` - 私有网络C类
- `169.254.0.0/16` - 链路本地地址
- `fe80::/10` - IPv6链路本地

### 配置文件位置

白名单配置: `/vol1/@appshare/crowdsec/crowdsec/parsers/s02-enrich/whitelists.yaml`
决策配置: `/vol1/@appshare/crowdsec/crowdsec/profiles.yaml`

## 管理命令

### 查看已安装的规则

```bash
# 列出所有已安装的场景规则
cscli scenarios list

# 列出所有已安装的集合
cscli collections list

# 列出所有已安装的解析器
cscli parsers list
```

### 查看检测和决策

```bash
# 查看当前的决策（被阻止的IP）
cscli decisions list

# 查看最近的警报
cscli alerts list

# 查看CrowdSec状态
cscli status
```

### 手动管理规则

```bash
# 安装新的场景规则
cscli scenarios install crowdsecurity/ssh-bf

# 卸载场景规则
cscli scenarios remove crowdsecurity/ssh-bf

# 安装新的集合
cscli collections install crowdsecurity/nginx

# 卸载集合
cscli collections remove crowdsecurity/nginx
```

### 管理白名单

```bash
# 手动添加IP到白名单（临时）
cscli decisions add --ip <IP地址> --type whitelist --duration 1h

# 删除IP的阻止
cscli decisions delete --ip <IP地址>

# 刷新所有规则
cscli hub update
```

### 重载配置

```bash
# 重载CrowdSec配置
pkill -HUP crowdsec

# 或通过服务管理
systemctl reload crowdsec
```

## 自定义配置

### 添加自定义日志采集

编辑 `/vol1/@appshare/crowdsec/acquis.d/` 目录下的配置文件：

```yaml
---
# 自定义日志采集示例
filenames:
  - /path/to/your/log/file.log
labels:
  type: nginx  # 根据实际日志类型选择: nginx, apache2, syslog, sshd等
```

### 修改封禁策略

编辑 `/vol1/@appshare/crowdsec/crowdsec/profiles.yaml` 文件：

```yaml
name: custom_remediation
filters:
 - Alert.Remediation == true && Alert.GetScope() == "Ip"
decisions:
 - type: ban
   duration: 8h  # 修改封禁时长
on_success: break
```

### 添加自定义白名单

编辑 `/vol1/@appshare/crowdsec/crowdsec/parsers/s02-enrich/whitelists.yaml`：

```yaml
whitelist:
  reason: "Custom whitelisted IP"
  ip:
    - "YOUR_IP_ADDRESS"
    - "YOUR_NETWORK/CIDR"
```

## 故障排除

### 规则未生效

1. 检查日志采集配置是否正确
   ```bash
   cscli inspect acquisition
   ```

2. 检查CrowdSec服务状态
   ```bash
   systemctl status crowdsec
   cscli status
   ```

3. 查看CrowdSec日志
   ```bash
   tail -f /var/log/crowdsec.log
   ```

### 误封IP

1. 查看决策详情
   ```bash
   cscli decisions list --ip <IP地址>
   ```

2. 删除错误决策
   ```bash
   cscli decisions delete --ip <IP地址>
   ```

3. 将IP添加到白名单

### 日志采集问题

1. 检查日志文件是否存在且有读权限
   ```bash
   ls -l /var/log/nginx/*.log
   ```

2. 检查采集配置语法
   ```bash
   cscli inspect acquisition
   ```

3. 重载CrowdSec服务
   ```bash
   systemctl reload crowdsec
   ```

## 注意事项

1. **白名单管理**: 始终将您的本地网络IP添加到白名单，避免误封自己
2. **规则更新**: 定期运行 `cscli hub update` 更新规则库
3. **监控警报**: 定期检查 `cscli alerts list` 了解系统安全状况
4. **备份配置**: 修改配置前建议备份原始配置文件
5. **性能考虑**: 规则过多可能影响性能，根据实际需求启用规则

## 配置脚本

- 主安装脚本: `/vol1/1000/yaya/fn-app/fn-app/crowdsec-fn/cmd/install_callback`
- NAS规则配置: `/vol1/1000/yaya/fn-app/fn-app/crowdsec-fn/cmd/install_nas_scenarios`

## 更多信息

- CrowdSec官方文档: https://docs.crowdsec.net/
- 集合和规则库: https://hub.crowdsec.net/
- 社区支持: https://discourse.crowdsec.net/