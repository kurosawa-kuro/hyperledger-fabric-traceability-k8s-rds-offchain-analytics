# ================================
# バックエンド開発コマンド
# ================================

# Docker設定
BACKEND_DOCKER_USERNAME := kurosawakuro
BACKEND_DOCKER_IMAGE := backend-8080
BACKEND_DOCKER_TAG := latest
BACKEND_CONTAINER_NAME := backend-container
BACKEND_PORT := 8080

# Docker完全イメージ名
BACKEND_DOCKER_FULL_IMAGE := $(BACKEND_DOCKER_USERNAME)/$(BACKEND_DOCKER_IMAGE):$(BACKEND_DOCKER_TAG)

# ECR設定
ECR_REPO := 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/backend-8080
ECR_TAG ?= $(BACKEND_DOCKER_TAG)
ECR_FULL_IMAGE := $(ECR_REPO):$(ECR_TAG)

# ================================
# 開発コマンド
# ================================

# 開発サーバー起動
backend-dev:
	cd src/backend && GO_ENV=dev go run main.go

# 依存関係整理
backend-mod-tidy:
	cd src/backend && go mod tidy

# APIテスト実行
backend-test:
	curl http://localhost:$(BACKEND_PORT)/api/health
	curl http://localhost:$(BACKEND_PORT)/api/v1/ping

# 本番環境APIテスト
backend-test-prod:
	curl http://localhost:$(BACKEND_PORT)/api/health
	curl http://localhost:$(BACKEND_PORT)/api/v1/ping

# ================================
# Docker関連コマンド
# ================================

# Dockerイメージビルド
backend-docker-build:
	cd src/backend && docker build -t $(BACKEND_DOCKER_FULL_IMAGE) .

# Dockerコンテナ起動
backend-docker-run:
	cd src/backend && docker run -p $(BACKEND_PORT):$(BACKEND_PORT) --name $(BACKEND_CONTAINER_NAME) $(BACKEND_DOCKER_FULL_IMAGE)

# DockerHubにプッシュ
backend-docker-push-dockerhub:
	cd src/backend && docker push $(BACKEND_DOCKER_FULL_IMAGE)

# ECRにプッシュ
backend-docker-push-ecr:
	cd src/backend && docker push $(ECR_FULL_IMAGE)

# コンテナ停止と削除
backend-docker-stop:
	docker stop $(BACKEND_CONTAINER_NAME) && docker rm $(BACKEND_CONTAINER_NAME)

# コンテナログ確認
backend-docker-logs:
	docker logs $(BACKEND_CONTAINER_NAME)

# コンテナシェルアクセス
backend-docker-shell:
	docker exec -it $(BACKEND_CONTAINER_NAME) /bin/sh

# ================================
# 便利機能
# ================================

# イメージビルドとDockerHubプッシュ
backend-deploy: backend-docker-build backend-docker-push-dockerhub

# イメージビルドとコンテナ起動（一括実行）
backend-docker-all: backend-docker-build backend-docker-run
	@echo "バックエンドコンテナを起動しました。テストするには 'make backend-test' を実行してください" 