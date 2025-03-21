# ================================
# インフラ管理コマンド
# ================================

# 基本設定
TF_CMD := terraform
TF_PLAN_FILE := plan.tfplan

# コンポーネント一覧
TF_COMPONENTS := ssm fargate

# ディレクトリパス設定
TF_SSM_DIR := infra/ssm
TF_FARGATE_DIR := infra/fargate

# ================================
# ヘルパー関数
# ================================

# 指定ディレクトリでTerraformコマンド実行
define tf-cmd
	cd $(2) && $(TF_CMD) $(1)
endef

# プラン作成
define tf-plan
	cd $(1) && $(TF_CMD) plan $(2) -out=$(TF_PLAN_FILE)
endef

# プラン適用
define tf-apply
	cd $(1) && $(TF_CMD) apply $(TF_PLAN_FILE)
endef

# リソース削除
define tf-destroy
	cd $(1) && $(TF_CMD) destroy $(2)
endef

# ================================
# SSMコンポーネント操作
# ================================

# SSMデプロイ（標準）
tf-ssm-deploy:
	cd $(TF_SSM_DIR) && $(TF_CMD) init
	$(call tf-plan,$(TF_SSM_DIR),)
	$(call tf-apply,$(TF_SSM_DIR))

# SSMデプロイ（設定ファイル使用）
tf-ssm-deploy-env:
	cd $(TF_SSM_DIR) && $(TF_CMD) init
	$(call tf-plan,$(TF_SSM_DIR),-var-file=terraform.tfvars)
	$(call tf-apply,$(TF_SSM_DIR))

# SSM設定検証
tf-ssm-validate:
	$(call tf-cmd,validate,$(TF_SSM_DIR))

# SSMファイル整形
tf-ssm-fmt:
	$(call tf-cmd,fmt -recursive,$(TF_SSM_DIR))

# SSM状態確認
tf-ssm-status:
	$(call tf-cmd,state list,$(TF_SSM_DIR))

# SSM削除プラン作成
tf-ssm-plan-destroy:
	$(call tf-plan,$(TF_SSM_DIR),-destroy)

# SSM削除（確認あり）
tf-ssm-destroy:
	$(call tf-destroy,$(TF_SSM_DIR),)

# SSM削除（自動承認）
tf-ssm-destroy-auto:
	$(call tf-destroy,$(TF_SSM_DIR),-auto-approve)

# ================================
# Fargateコンポーネント操作
# ================================

# Fargateデプロイ
tf-fargate-deploy:
	cd $(TF_FARGATE_DIR) && $(TF_CMD) init
	$(call tf-plan,$(TF_FARGATE_DIR),)
	$(call tf-apply,$(TF_FARGATE_DIR))

# Fargate設定検証
tf-fargate-validate:
	$(call tf-cmd,validate,$(TF_FARGATE_DIR))

# Fargateファイル整形
tf-fargate-fmt:
	$(call tf-cmd,fmt -recursive,$(TF_FARGATE_DIR))

# Fargate状態確認
tf-fargate-status:
	$(call tf-cmd,state list,$(TF_FARGATE_DIR))

# Fargate削除（確認あり）
tf-fargate-destroy:
	$(call tf-destroy,$(TF_FARGATE_DIR),)

# Fargate削除（自動承認）
tf-fargate-destroy-auto:
	$(call tf-destroy,$(TF_FARGATE_DIR),-auto-approve)

# ================================
# 一括操作コマンド
# ================================

# 全コンポーネントデプロイ
tf-deploy-all: tf-ssm-deploy tf-fargate-deploy

# 全コンポーネント削除
tf-destroy-all: tf-fargate-destroy tf-ssm-destroy

# 全ファイル整形
tf-fmt-all:
	for comp in $(TF_COMPONENTS); do \
		$(MAKE) tf-$$comp-fmt; \
	done

# 全設定検証
tf-validate-all:
	for comp in $(TF_COMPONENTS); do \
		$(MAKE) tf-$$comp-validate; \
	done