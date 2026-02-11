#!/bin/bash

# 测试飞牛系统 SSH 日志解析器

CONFIG_DIR="/vol1/@appshare/crowdsec/crowdsec"
CROWDSEC_BIN="/vol1/1000/yaya/fn-app/fn-app/crowdsec-fn/app/server/crowdsec"

echo "========================================="
echo "测试飞牛系统 SSH 日志解析器"
echo "========================================="
echo ""

# 测试日志
TEST_LOG="[10 15:21:37.930] [info] [2306] sshd log:  Failed password for invalid user aabb from 240e:30f:9a49:6300:e789:f434:9805:4235 port 11382 ssh2"

echo "测试日志:"
echo "$TEST_LOG"
echo ""

# 创建临时测试文件
TEMP_LOG="/tmp/fnnas_ssh_test.log"
echo "$TEST_LOG" > "$TEMP_LOG"

echo "测试配置文件:"
echo "- 日志类型: fnnas"
echo "- 服务: ssh"
echo "- 解析器: crowdsecurity/fnnas-ssh-logs"
echo ""

# 检查解析器配置
echo "检查解析器配置:"
if grep -q "evt.Line.Labels.type == 'fnnas'" "$CONFIG_DIR/parsers/s00-raw/fnnas-ssh-logs.yaml"; then
    echo "✓ 解析器配置正确 (type == 'fnnas')"
else
    echo "✗ 解析器配置错误"
    echo "  当前配置:"
    grep "filter:" "$CONFIG_DIR/parsers/s00-raw/fnnas-ssh-logs.yaml"
fi
echo ""

# 检查日志采集配置
echo "检查日志采集配置:"
if grep -q "type: fnnas" "$CONFIG_DIR/../acquis.d/syslog.yaml"; then
    echo "✓ 日志采集配置正确 (type: fnnas)"
else
    echo "✗ 日志采集配置错误"
    echo "  当前配置:"
    grep -A 3 "eventlogger_service.log" "$CONFIG_DIR/../acquis.d/syslog.yaml"
fi
echo ""

# 检查已安装的解析器
echo "已安装的 SSH 相关解析器:"
/vol1/1000/yaya/fn-app/fn-app/crowdsec-fn/app/server/cscli -c "$CONFIG_DIR/config.yaml" parsers list 2>&1 | grep -E "ssh|fnnas"
echo ""

echo "========================================="
echo "测试完成"
echo "========================================="
echo ""
echo "下一步:"
echo "1. 如果配置正确，请重启 CrowdSec 服务"
echo "2. 添加更多测试日志到 /usr/trim/logs/eventlogger_service.log"
echo "3. 检查是否产生告警和封禁"