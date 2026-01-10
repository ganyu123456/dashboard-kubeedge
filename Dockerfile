# ==================== 后端构建阶段 ====================
FROM golang:1.23-alpine AS backend-builder

WORKDIR /workspace

# 安装构建依赖
RUN apk add --no-cache git make

# 设置 Go 代理（使用国内镜像加速）
ENV GOPROXY=https://goproxy.cn,direct
ENV GO111MODULE=on

# 复制 go.work 和相关模块的 go.mod/go.sum
COPY go.work go.work.sum ./
COPY modules/api/go.mod modules/api/go.sum modules/api/
COPY modules/common/client/go.mod modules/common/client/go.sum modules/common/client/
COPY modules/common/errors/go.mod modules/common/errors/go.sum modules/common/errors/

# 下载依赖
WORKDIR /workspace/modules/api
RUN go mod download

# 复制源代码
WORKDIR /workspace
COPY modules/api/ modules/api/
COPY modules/common/ modules/common/

# 构建后端
WORKDIR /workspace/modules/api
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags="-w -s" -o /api-server main.go

# ==================== 前端构建阶段 ====================
FROM node:20-alpine AS frontend-builder

WORKDIR /app

# 安装构建依赖
RUN apk add --no-cache libc6-compat

# 复制 package.json 和 lock 文件
COPY modules/web/package.json modules/web/package-lock.json* ./

# 安装依赖 (如果 lock 文件存在则使用 npm ci，否则使用 npm install)
RUN if [ -f package-lock.json ]; then \
      npm ci --legacy-peer-deps || npm install --legacy-peer-deps; \
    else \
      npm install --legacy-peer-deps; \
    fi

# 复制前端源代码
COPY modules/web/ ./

# 构建前端
RUN npm run build

# ==================== 最终运行镜像 ====================
FROM node:20-alpine AS runner

WORKDIR /app

# 安装运行时依赖
RUN apk add --no-cache ca-certificates tzdata wget

# 设置时区
ENV TZ=Asia/Shanghai

# 创建非root用户
RUN addgroup --system --gid 1001 appgroup && \
    adduser --system --uid 1001 appuser

# 从后端构建阶段复制可执行文件
COPY --from=backend-builder /api-server /usr/local/bin/api-server
RUN chmod +x /usr/local/bin/api-server

# 从前端构建阶段复制文件
COPY --from=frontend-builder --chown=appuser:appgroup /app/public ./public
COPY --from=frontend-builder --chown=appuser:appgroup /app/.next/standalone ./
COPY --from=frontend-builder --chown=appuser:appgroup /app/.next/static ./.next/static

# 创建启动脚本
RUN echo '#!/bin/sh' > /start.sh && \
    echo 'echo "🚀 启动 KubeEdge Dashboard API Server..."' >> /start.sh && \
    echo '/usr/local/bin/api-server &' >> /start.sh && \
    echo 'API_PID=$!' >> /start.sh && \
    echo 'echo "✅ API Server 已启动 (PID: $API_PID)"' >> /start.sh && \
    echo 'echo "🌐 启动前端服务器..."' >> /start.sh && \
    echo 'cd /app' >> /start.sh && \
    echo 'node server.js &' >> /start.sh && \
    echo 'WEB_PID=$!' >> /start.sh && \
    echo 'echo "✅ 前端服务器已启动 (PID: $WEB_PID)"' >> /start.sh && \
    echo 'echo "📦 KubeEdge Dashboard 已启动"' >> /start.sh && \
    echo 'echo "   - API Server: http://0.0.0.0:8080"' >> /start.sh && \
    echo 'echo "   - Web UI: http://0.0.0.0:3000"' >> /start.sh && \
    echo 'wait' >> /start.sh && \
    chmod +x /start.sh

# 设置环境变量
ENV NODE_ENV=production \
    PORT=3000 \
    HOSTNAME="0.0.0.0"

# 切换到非root用户
USER appuser

# 暴露端口
EXPOSE 3000 8080

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/ || exit 1

# 启动应用
CMD ["/start.sh"]

