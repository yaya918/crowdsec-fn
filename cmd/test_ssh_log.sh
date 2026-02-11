#!/bin/bash

# CrowdSec SSH 日志测试脚本
# 用于测试飞牛系统 SSH 日志是否能被正确解析和封禁

CROWDSEC_BIN="/vol1/1000/yaya/fn-app/fn-app/crowdsec-fn/app/server/crowdsec"
CSCLI_BIN="/vol1/1000/yaya/fn-app/fn-app/crowdsec-fn/app/server/cscli"
CONFIG_DIR="/vol1/@appshare/crowdsec/crowdsec"
LOG_FILE="/usr/trim/logs/eventlogger_service.log"
TEST_IP="240e:30f:9a49:6300:e789:f434:9805:4235"

echo "========================================="
echo "CrowdSec SSH 日志测试脚本"
echo "========================================="
echo ""

# 检查 CrowdSec 是否运行
if ! pgrep -f crowdsec > /dev/null; then
    echo "错误: CrowdSec 未运行"
    echo "请先启动 CrowdSec 服务"
    exit 1
fi

echo "1. CrowdSec 服务状态: 运行中"
echo ""

# 备份原始日志
echo "2. 备份原始日志文件..."
if [ -f "$LOG_FILE" ]; then
    cp "$LOG_FILE" "${LOG_FILE}.backup.$(date +%s)"
    echo "   已备份到: ${LOG_FILE}.backup.$(date +%s)"
fi
echo ""

# 写入测试日志
echo "3. 写入测试 SSH 日志..."
cat >> "$LOG_FILE" << 'EOF'
[10 15:21:37.930] [info] [2306] sshd log:  Failed none for invalid user aabb from 240e:30f:9a49:6300:e789:f434:9805:4235 port 11382 ssh2
[10 15:21:38.266] [info] [2306] sshd log:  Failed password for invalid user aabb from 240e:30f:9a49:6300:e789:f434:9805:4235 port 11382 ssh2
[10 15:21:38.266] [info] [2306] sshd ip: aabb, len: 4
[10 15:21:38.462] [info] [2306] sshd log:  Failed password for invalid user aabb from 240e:30f:9a49:6300:e789:f434:9805:4235 port 11382 ssh2
[10 15:21:38.462] [info] [2306] sshd ip: aabb, len: 4
[10 15:21:38.525] [info] [2306] sshd log:  Connection closed by invalid user aabb 240e:30f:9a49:6300:e789:f434:9805:4235 port 11382 [preauth]
[10 15:21:39.693] [info] [2306] sshd log:  Invalid user aabb from 240e:30f:9a49:6300:e789:f434:9805:4235 port 11396
[10 15:21:39.834] [info] [2306] sshd log:  Failed none for invalid user aabb from 240e:30f:9a49:6300:e789:f434:9805:4235 port 11396 ssh2
[10 15:21:40.018] [info] [2306] sshd log:  Failed password for invalid user aabb from 240e:30f:9a49:6300:e789:f434:9805:4235 port 11396 ssh2
[10 15:21:40.018] [info] [2306] sshd ip: aabb, len: 4
[10 15:21:40.466] [info] [2306] sshd log:  Failed password for invalid user aabb from 240e:30f:9a49:6300:e789:f434:9805:4235 port 11396 ssh2
[10 15:21:40.466] [info] [2306] sshd ip: aabb, len: 4
[10 15:21:40.526] [info] [2306] sshd log:  Connection closed by invalid user aabb 240e:30f:9a49:6300:e789:f434:9805:4235 port 11396 [preauth]
[10 15:21:41.815] [info] [2306] sshd log:  Invalid user aabb from 240e:30f:9a49:6300:e789:f434:9805:4235 port 11408
[10 15:21:41.959] [info] [2306] sshd log:  Failed none for invalid user aabb from 240e:30f:9a49:6300:e789:f434:9805:4235 port 11408 ssh2
[10 15:21:42.166] [info] [2306] sshd log:  Failed password for invalid user aabb from 240e:30f:9a49:6300:e789:f434:9805:4235 port 11408 ssh2
[10 15:21:42.166] [info] [2306] sshd ip: aabb, len: 4
[10 15:21:42.443] [info] [2306] sshd log:  Failed password for invalid user aabb from 240e:30f:9a49:6300:e789:f434:9805:4235 port 11408 ssh2
[10 15:21:42.443] [info] [2306] sshd ip: aabb, len: 4
[10 15:21:42.502] [info] [2306] sshd log:  Connection closed by invalid user aabb 240e:30f:9a49:6300:e789:f434:9805:4235 port 11408 [preauth]
[10 15:21:43.713] [info] [2306] sshd log:  Invalid user aabb from 240e:30f:9a49:6300:e789:f434:9805:4235 port 11424
[10 15:21:44.069] [info] [2306] sshd log:  Failed none for invalid user aabb from 240e:30f:9a49:6300:e789:f434:9805:4235 port 11424 ssh2
[10 15:21:44.256] [info] [2306] sshd log:  Failed password for invalid user aabb from 240e:30f:9a49:6300:e789:f434:9805:4235 port 11424 ssh2
[10 15:21:44.256] [info] [2306] sshd ip: aabb, len: 4
[10 15:21:44.441] [info] [2306] sshd log:  Failed password for invalid user aabb from 240e:30f:9a49:6300:e789:f434:9805:4235 port 11424 ssh2
[10 15:21:44.441] [info] [2306] sshd ip: aabb, len: 4
[10 15:21:44.510] [info] [2306] sshd log:  Connection closed by invalid user aabb 240e:30f:9a49:6300:e789:f434:9805:4235 port 11424 [preauth]
EOF
echo "   已写入 20 条测试日志"
echo ""

# 通知 CrowdSec 重读日志
echo "4. 通知 CrowdSec 重读日志..."
pkill -HUP crowdsec
sleep 3
echo "   已发送 HUP 信号"
echo ""

# 等待 CrowdSec 处理
echo "5. 等待 CrowdSec 处理日志 (10秒)..."
for i in {1..10}; do
    echo -n "."
    sleep 1
done
echo ""
echo ""

# 检查告警
echo "6. 检查 CrowdSec 告警..."
ALERTS=$("$CSCLI_BIN" -c "$CONFIG_DIR/config.yaml" alerts list 2>&1)
if echo "$ALERTS" | grep -q "$TEST_IP"; then
    echo "   ✓ 检测到针对 IP 的告警"
    echo ""
    echo "   详细告警信息:"
    echo "$ALERTS" | grep -A 5 "$TEST_IP"
else
    echo "   ✗ 未检测到告警"
fi
echo ""

# 检查封禁
echo "7. 检查 CrowdSec 封禁决策..."
DECISIONS=$("$CSCLI_BIN" -c "$CONFIG_DIR/config.yaml" decisions list 2>&1)
if echo "$DECISIONS" | grep -q "$TEST_IP"; then
    echo "   ✓ IP 已被封禁"
    echo ""
    echo "   封禁详情:"
    echo "$DECISIONS" | grep -A 10 "$TEST_IP"
else
    echo "   ✗ IP 未被封禁"
    echo ""
    echo "   可能原因:"
    echo "   1. 攻击次数未达到阈值 (默认 5 次)"
    echo "   2. 日志未被正确解析"
    echo "   3. 场景规则未正确配置"
fi
echo ""

# 检查解析器状态
echo "8. 检查解析器状态..."
PARSERS=$("$CSCLI_BIN" -c "$CONFIG_DIR/config.yaml" parsers list 2>&1)
if echo "$PARSERS" | grep -q "fnnas-ssh-logs"; then
    echo "   ✓ 飞牛系统 SSH 解析器已安装"
else
    echo "   ✗ 飞牛系统 SSH 解析器未安装"
    echo ""
    echo "   当前已安装的解析器:"
    echo "$PARSERS" | grep -E "ssh|syslog"
fi
echo ""

# 显示所有当前封禁
echo "9. 当前所有封禁:"
echo "$DECISIONS"
echo ""

echo "========================================="
echo "测试完成"
echo "========================================="
echo ""
echo "提示:"
echo "- 如果 IP 未被封禁，可以继续添加更多测试日志"
echo "- 运行 'bash $0' 再次测试"
echo "- 恢复原始日志: cp ${LOG_FILE}.backup.* $LOG_FILE"