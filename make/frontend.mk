# ================================
# フロントエンド開発コマンド
# ================================

# Docker設定
FRONTEND_DOCKER_USERNAME := kurosawakuro
FRONTEND_DOCKER_IMAGE := frontend-3000
FRONTEND_DOCKER_TAG := latest
FRONTEND_CONTAINER_NAME := frontend-container

# Docker完全イメージ名
FRONTEND_DOCKER_FULL_IMAGE := $(FRONTEND_DOCKER_USERNAME)/$(FRONTEND_DOCKER_IMAGE):$(FRONTEND_DOCKER_TAG)

# ================================
# 開発コマンド
# ================================

# 開発サーバー起動
frontend-dev:
	cd src/frontend && npm run dev

# ビルド実行
frontend-build:
	cd src/frontend && npm run build

# ビルド済み環境起動
frontend-start:
	cd src/frontend && npm start

# Lint実行
frontend-lint:
	cd src/frontend && npm run lint

# テスト実行
frontend-test:
	cd src/frontend && npm test

# ================================
# Docker関連コマンド
# ================================

# Dockerイメージビルド
frontend-docker-build:
	cd src/frontend && docker build -t $(FRONTEND_DOCKER_FULL_IMAGE) .

# Dockerコンテナ起動
frontend-docker-run:
	cd src/frontend && docker run -p 3000:3000 --name $(FRONTEND_CONTAINER_NAME) $(FRONTEND_DOCKER_FULL_IMAGE)

# バックグラウンドでコンテナ起動
frontend-docker-run-detached:
	cd src/frontend && docker run -d -p 3000:3000 --name $(FRONTEND_CONTAINER_NAME) $(FRONTEND_DOCKER_FULL_IMAGE)

# DockerHubにイメージをプッシュ
frontend-docker-push-dockerhub:
	cd src/frontend && docker push $(FRONTEND_DOCKER_FULL_IMAGE)

# ECRにイメージをプッシュ
frontend-docker-push-ecr:
	cd src/frontend && docker push $(ECR_FULL_IMAGE)

# コンテナ停止と削除
frontend-docker-stop:
	docker stop $(FRONTEND_CONTAINER_NAME) && docker rm $(FRONTEND_CONTAINER_NAME)

# コンテナログ確認
frontend-docker-logs:
	docker logs $(FRONTEND_CONTAINER_NAME)

# コンテナシェルアクセス
frontend-docker-shell:
	docker exec -it $(FRONTEND_CONTAINER_NAME) /bin/sh

# ================================
# 便利機能
# ================================

# イメージビルドとDockerHubプッシュ
frontend-deploy: frontend-docker-build frontend-docker-push-dockerhub

# イメージビルドとコンテナ起動（一括実行）
frontend-docker-all: frontend-docker-build frontend-docker-run
	@echo "フロントエンドコンテナを起動しました。ブラウザで http://localhost:3000 にアクセスしてください"

