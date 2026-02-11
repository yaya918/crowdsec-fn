#!/bin/bash

# 简单测试 SSH 日志解析
# 使用正确的 crowdsec 测试方法

CROWDSEC_BIN="/vol1/1000/yaya/fn-app/fn-app/crowdsec-fn/app/server/crowdsec"
CONFIG_DIR="/vol1/@appshare/crowdsec/crowdsec"
TEMP_DIR="/tmp/crowdsec_test"
TEMP_LOG="$TEMP_DIR/eventlogger_service.log"

echo "========================================="
echo "简单测试 SSH 日志解析"
echo "========================================="
echo ""

# 创建测试目录和文件
mkdir -p "$TEMP_DIR"

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

# 创建临时采集配置
mkdir -p "$TEMP_DIR/acquis.d"
cat > "$TEMP_DIR/acquis.d/fnnas-test.yaml" << 'EOF'
---
filenames:
  - /tmp/crowdsec_test/eventlogger_service.log
labels:
  type: fnnas
  service: ssh
EOF

echo "测试日志解析..."
echo "========================================="

# 使用 crowdsec -t 模式测试
"$CROWDSEC_BIN" -c "$CONFIG_DIR/config.yaml" -t \
  -acquisition-dir "$TEMP_DIR/acquis.d" \
  -type fnnas \
  -label service=ssh \
  -dump-data "$TEMP_DIR/dump.json" \
  file:///tmp/crowdsec_test/eventlogger_service.log 2>&1 | grep -E "Loaded|source_ip|sshd_client_ip|error|fatal" | head -50

echo ""
echo "========================================="
echo ""

# 检查解析结果
if [ -f "$TEMP_DIR/dump.json" ]; then
    echo "✓ 解析结果已生成"
    echo ""
    echo "检查 IP 提取结果:"
    grep -o "240e:30f:9a49:6300:e789:f434:9805:4235" "$TEMP_DIR/dump.json" | wc -l
    echo "次找到目标 IP"
    echo ""
    
    if grep -q "240e:30f:9a49:6300:e789:f434:9805:4235" "$TEMP_DIR/dump.json"; then
        echo "✓ 日志解析成功！"
        echo ""
        echo "IP 提取详情:"
        grep -B 2 -A 2 "240e:30f:9a49:6300:e789:f434:9805:4235" "$TEMP_DIR/dump.json" | head -20
    else
        echo "✗ IP 未被提取"
        echo ""
        echo "部分输出:"
        head -20 "$TEMP_DIR/dump.json"
    fi
else
    echo "✗ 未生成解析结果文件"
fi

# 清理
rm -rf "$TEMP_DIR"
echo ""
echo "========================================="
echo "测试完成"
echo "========================================="