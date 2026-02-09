#!/bin/bash

# CrowdSec Safeline Nginx 日志格式修复脚本
# 此脚本将 Safeline Nginx 的自定义日志格式修改为增强格式，包含请求体等详细信息，以便 CrowdSec 进行深度检测

set -e

# 日志函数
log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
    if [ -n "${TRIM_PKGVAR}" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "${TRIM_PKGVAR}/info.log"
    fi
}

# Safeline Nginx 配置目录
SAFELINE_NGINX_DIR="/vol1/1000/docker/safeline/resources/nginx/sites-enabled"

# 检查目录是否存在
if [ ! -d "$SAFELINE_NGINX_DIR" ]; then
    log_msg "Safeline Nginx 配置目录不存在: $SAFELINE_NGINX_DIR"
    log_msg "跳过 Safeline Nginx 日志格式修复"
    exit 0
fi

log_msg "开始修复 Safeline Nginx 日志格式..."
log_msg "配置目录: $SAFELINE_NGINX_DIR"

# 增强的 Nginx 日志格式（包含请求体和更多信息，支持 CrowdSec 深度检测）
ENHANCED_LOG_FORMAT='$remote_addr - $remote_user [$time_local] "$request_method $request_uri $server_protocol" $status $body_bytes_sent "$http_referer" "$http_user_agent" $request_time $upstream_response_time $request_length $bytes_sent "$http_x_forwarded_for" "$http_host" "$http_accept" "$http_accept_language" "$http_accept_encoding" "$connection" "$connection_requests" "$request_body" "$http_content_type" "$content_length"'

# 备份目录
BACKUP_DIR="${SAFELINE_NGINX_DIR}/backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# 处理所有配置文件
for config_file in "$SAFELINE_NGINX_DIR"/IF_backend_*; do
    if [ ! -f "$config_file" ]; then
        continue
    fi

    config_name=$(basename "$config_file")
    log_msg "处理配置文件: $config_name"

    # 备份原文件
    cp "$config_file" "$BACKUP_DIR/$config_name"
    log_msg "已备份: $BACKUP_DIR/$config_name"

    # 检查文件中是否有自定义日志格式
    if grep -q "log_format safeline_" "$config_file"; then
        log_msg "发现自定义日志格式，正在修改..."

        # 获取 safeline 格式的名称（例如 safeline_1, safeline_2 等）
        format_name=$(grep "log_format safeline_" "$config_file" | head -1 | awk '{print $2}')

        # 构建新的log_format行
        new_log_format="log_format $format_name '\$remote_addr - \$remote_user [\$time_local] \"\$request_method \$request_uri \$server_protocol\" \$status \$body_bytes_sent \"\$http_referer\" \"\$http_user_agent\" \$request_time \$upstream_response_time \$request_length \$bytes_sent \"\$http_x_forwarded_for\" \"\$http_host\" \"\$http_accept\" \"\$http_accept_language\" \"\$http_accept_encoding\" \"\$connection\" \"\$connection_requests\" \"\$request_body\" \"\$http_content_type\" \"\$content_length\"';"

        # 使用更安全的替换方式：创建临时文件
        temp_file="${config_file}.tmp"
        awk -v new="$new_log_format" -v fname="log_format $format_name" '
            $0 ~ fname {
                print new
                next
            }
            { print }
        ' "$config_file" > "$temp_file"

        # 检查临时文件是否成功创建且有内容
        if [ -s "$temp_file" ]; then
            mv "$temp_file" "$config_file"
            log_msg "已将 $format_name 格式修改为增强格式（包含请求体和详细信息）"
        else
            log_msg "警告: 临时文件创建失败，跳过修改 $config_file"
            rm -f "$temp_file"
        fi
    else
        log_msg "未发现自定义日志格式，跳过"
    fi
done

# 检查是否需要重载 Nginx
if [ -d "/vol1/1000/docker/safeline" ]; then
    log_msg "检查 Safeline Nginx 容器状态..."

    # 尝试重载 Nginx 配置
    if docker ps --format '{{.Names}}' | grep -q "safeline.*nginx"; then
        nginx_container=$(docker ps --format '{{.Names}}' | grep "safeline.*nginx" | head -1)
        log_msg "找到 Safeline Nginx 容器: $nginx_container"

        # 测试配置文件
        if docker exec "$nginx_container" nginx -t 2>&1 | grep -q "syntax is ok\|successful"; then
            log_msg "Nginx 配置文件语法检查通过"
            
            # 重载 Nginx
            if docker exec "$nginx_container" nginx -s reload 2>&1; then
                log_msg "Safeline Nginx 配置已重载"
            else
                log_msg "警告: Safeline Nginx 重载失败"
            fi
        else
            log_msg "警告: Nginx 配置文件语法检查失败，已恢复备份"
            # 恢复备份
            for backup_file in "$BACKUP_DIR"/*; do
                if [ -f "$backup_file" ]; then
                    backup_name=$(basename "$backup_file")
                    cp "$backup_file" "$SAFELINE_NGINX_DIR/$backup_name"
                fi
            done
        fi
    else
        log_msg "未找到运行中的 Safeline Nginx 容器"
        log_msg "配置文件已修改，需要手动重载 Safeline Nginx"
    fi
fi

log_msg "Safeline Nginx 日志格式修复完成"
log_msg "备份文件保存在: $BACKUP_DIR"

exit 0