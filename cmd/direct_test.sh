#!/bin/bash

# 直接测试 SSH 日志解析
# 使用 crowdsec 的 -t 模式测试日志解析

CROWDSEC_BIN="/vol1/1000/yaya/fn-app/fn-app/crowdsec-fn/app/server/crowdsec"
CONFIG_DIR="/vol1/@appshare/crowdsec/crowdsec"
TEMP_LOG="/tmp/test_ssh.log"

echo "========================================="
echo "直接测试 SSH 日志解析"
echo "========================================="
echo ""

# 创建测试日志文件
cat > "$TEMP_LOG" << 'EOF'
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

echo "测试日志文件: $TEMP_LOG"
echo "日志行数: $(wc -l < $TEMP_LOG)"
echo ""

# 测试解析（使用 crowdsec -t 模式）
echo "测试日志解析..."
echo "========================================="
"$CROWDSEC_BIN" -c "$CONFIG_DIR/config.yaml" -t -dsn "$TEMP_LOG" -type fnnas 2>&1 | head -100
echo ""
echo "========================================="
echo ""

# 检查是否有解析结果
if "$CROWDSEC_BIN" -c "$CONFIG_DIR/config.yaml" -t -dsn "$TEMP_LOG" -type fnnas 2>&1 | grep -q "source_ip.*240e:30f"; then
    echo "✓ 日志解析成功！"
    echo "  检测到源 IP: 240e:30f:9a49:6300:e789:f434:9805:4235"
    echo ""
    echo "解析详情:"
    "$CROWDSEC_BIN" -c "$CONFIG_DIR/config.yaml" -t -dsn "$TEMP_LOG" -type fnnas 2>&1 | grep -A 2 "source_ip"
else
    echo "✗ 日志解析失败"
    echo ""
    echo "完整输出:"
    "$CROWDSEC_BIN" -c "$CONFIG_DIR/config.yaml" -t -dsn "$TEMP_LOG" -type fnnas 2>&1
fi

# 清理
rm -f "$TEMP_LOG"