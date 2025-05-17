VPC（Virtual Private Cloud／仮想ネットワーク）
　→ クラウド上に“自分専用のネットワーク空間”を作るため

パブリックサブネット
　→ インターネットからアクセス可能な領域（ALBやNAT配置先）を作るため

プライベートサブネット
　→ インターネットから直接アクセスできない“内部専用エリア”（ECS・RDSの配置先）を作るため

インターネットゲートウェイ（IGW）
　→ VPC内リソース（ALBなど）がインターネットと通信できるようにするため

NAT Gateway
　→ プライベートサブネット内のECSタスク等が「外向き通信」できるようにするため（パッチ適用・外部API連携など）

ルートテーブル
　→ サブネットごとに「どのネットワーク経路を使うか」を設定するため

セキュリティグループ（SG）
　→ サーバーやコンテナの通信を“ファイアウォール”として制御し、必要な通信だけ許可するため

ALB（Application Load Balancer）
　→ インターネットからのアクセスを受けて、ECSの各コンテナへ“自動で振り分け”するため

Target Group
　→ ALBからECSタスクへ通信を割り振る“グループ”を定義するため

ECS Fargate
　→ サーバーレスでDockerコンテナを“自動運用”し、Webサービスをホストするため

ECR（Elastic Container Registry）
　→ 独自Dockerイメージ（Python Flaskアプリなど）をAWSクラウドに“保管・管理”するため

RDS（Relational Database Service）
　→ ECSコンテナやアプリケーションから使える“クラウドDB”を自動で構築・運用するため

IAMロール／ポリシー
　→ ECSやTerraformなどがAWSサービスに安全にアクセスするための“権限”を管理するため

Terraform（IaC管理）
　→ すべてのAWSリソースを「コードで自動構築＆管理」するため


---

## 特徴

- **TerraformのみでAWSインフラをフル自動構築**
- VPC（ネットワーク）
- Public/Private Subnet
- NAT Gateway
- ALB（ロードバランサ）
- ECS Fargate（Dockerコンテナ運用）
- RDS（DB）
- Security Group（ファイアウォール）
- Terraformの状態ファイル（tfstate）はS3バケットで一元管理し、クラウドリソース構成を安全かつ自動でバックアップ
- ECR（Elastic Container Registry）に独自Dockerイメージをpush
- Python FlaskによるWeb API/アプリをサンプル実装
- ALB経由でインターネット公開


---

```## ディレクトリ構成

ecs-fargate-docker-flask-rds-iac/
│
├── environments/
│ └── dev/
│ ├── main.tf # 環境構築のメイン
│ ├── variables.tf # 変数定義
│ ├── terraform.tfvars # 変数値（ローカル）
│ └── backend.tf # S3リモートState管理
│
├── modules/
│ ├── vpc/ # ネットワーク基盤
│ ├── alb/ # ロードバランサ
│ ├── ecs/ # Fargateサービス
│ ├── rds/ # DB
│
├── myapp-python/
│ ├── Dockerfile
│ ├── main.py
│ └── requirements.txt
│
└── .gitignore
└── README.md
```


---

## 実行手順（ローカル環境）

### 1. 必要なツール

- AWS CLI
- Terraform
- Docker
- Git
- （VSCode拡張：AWS Toolkit / Docker / Python など推奨）

### 2. AWS認証

- `aws configure` でアクセスキー等をセット
- 必要な権限: IAM/EC2/VPC/ECS/ECR/RDS/ALB/S3

### 3. Dockerイメージの作成＆ECR登録

```bash
cd myapp-python
docker build -t myapp:latest .
aws ecr get-login-password --region ap-northeast-1 | \
  docker login --username AWS --password-stdin <あなたのAWSアカウント>.dkr.ecr.ap-northeast-1.amazonaws.com
docker tag myapp:latest <上記URI>/myapp:latest
docker push <上記URI>/myapp:latest

4. Terraform構成
bash
コピーする
編集する

cd ecs-fargate-terraform/environments/dev
terraform init
terraform plan
terraform apply
