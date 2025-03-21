# ================================
# APIテストコマンド
# ================================

# テスト用変数
API_HOST ?= localhost
API_PORT ?= 8080
API_BASE_URL = http://$(API_HOST):$(API_PORT)

# 基本的なヘルスチェック
curl-health:
	curl $(API_BASE_URL)/api/health

# Ping APIテスト
curl-ping:
	curl $(API_BASE_URL)/api/v1/ping

# 基本APIテスト（複数エンドポイント）
curl-test: curl-health curl-ping
	@echo "基本APIテスト完了！"

# カスタムAPIテスト（パスを指定）
curl-path:
	@read -p "テストするAPIパスを入力してください: " path; \
	curl $(API_BASE_URL)/$$path

# 後方互換性のための古いコマンド
curl: curl-health
	@echo "注意：'make curl'は非推奨です。代わりに 'make curl-test' か 'make curl-health' をお使いください。" 