
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
- **ECR（Elastic Container Registry）に独自Dockerイメージをpush**
- **Python FlaskによるWeb API/アプリをサンプル実装**
- **ALB経由でインターネット公開**

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
└── README.md```


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
