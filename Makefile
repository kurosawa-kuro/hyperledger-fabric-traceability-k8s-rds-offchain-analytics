# ================================
# メインMakefile
# ================================

# サブMakefileの読み込み
include make/frontend.mk
include make/backend.mk
include make/curl.mk
include make/infra.mk

# ================================
# ヘルプコマンド
# ================================

# デフォルトのターゲット
.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "┌─────────────────────────────────────────────────────┐"
	@echo "│ 開発支援コマンド一覧                                │"
	@echo "└─────────────────────────────────────────────────────┘"
	@echo ""
	@echo "【フロントエンド】"
	@echo "  make frontend-dev         - 開発サーバー起動"
	@echo "  make frontend-build       - ビルド実行"
	@echo "  make frontend-start       - ビルド済み環境の起動"
	@echo "  make frontend-test        - テスト実行"
	@echo "  make frontend-docker-all  - Docker環境の構築と起動"
	@echo ""
	@echo "【バックエンド】"
	@echo "  make backend-dev          - 開発サーバー起動"
	@echo "  make backend-mod-tidy     - 依存関係の整理"
	@echo "  make backend-test         - APIテスト実行"
	@echo "  make backend-docker-all   - Docker環境の構築と起動"
	@echo ""
	@echo "【インフラ】"
	@echo "  make tf-deploy-all        - 全インフラのデプロイ"
	@echo "  make tf-validate-all      - 全インフラの検証"
	@echo "  make tf-fmt-all           - 全Terraformファイルの整形"
	@echo "  make tf-destroy-all       - 全インフラの削除"
	@echo ""
	@echo "詳細コマンドは各makeファイルを参照してください。"
	@echo "- make/frontend.mk: フロントエンド関連"
	@echo "- make/backend.mk: バックエンド関連"
	@echo "- make/infra.mk: インフラ関連"
	@echo "- make/curl.mk: APIテスト関連"

