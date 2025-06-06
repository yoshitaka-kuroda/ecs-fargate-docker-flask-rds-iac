# AWSWeb基盤フル自動構築（Terraform／ECS Fargate＋ALB＋RDS＋ECR＋VPC＋Flask）

---

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

- **TerraformでAWSインフラを自動構築**
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
├── environments/                     # 環境ごとの設定（dev/stg/prodなどを分けられる）
│   └── dev/                          # “開発環境（dev）”用フォルダ
│       ├── backend.tf                # ─ Terraform State を S3 で管理する設定
│       ├── main.tf                   # ─ 各モジュールを呼び出してリソースを一括構築するメイン定義
│       ├── variables.tf              # ─ main.tf で使う入力変数定義（例：env, vpc_cidr など）
│       └── terraform.tfvars          # ─ 変数の実際の値を定義（ローカル用。dev 環境向けの値）
│
├── modules/                          # 再利用可能な“個別コンポーネント”をまとめたモジュール群
│   ├── vpc/                          # ─ ネットワーク基盤
│   │   ├── main.tf                   #    • VPC, Public/Private サブネット, IGW, NAT Gateway, ルートテーブル定義
│   │   ├── variables.tf              #    • VPC の CIDR や AZ、サブネットの CIDR などの変数定義
│   │   └── outputs.tf                #    • 作成した VPC ID、サブネット ID 群などの出力定義
│   │
│   ├── alb/                          # ─ Application Load Balancer（ALB）関連
│   │   ├── main.tf                   #    • ALB 本体、セキュリティグループ、ターゲットグループ、リスナー定義
│   │   ├── variables.tf              #    • 使用する VPC ID、サブネット ID 群、セキュリティグループ設定など
│   │   └── outputs.tf                #    • ALB の DNS 名、ターゲットグループ ARN、セキュリティグループ ID など出力
│   │
│   ├── ecs/                          # ─ ECS Fargate サービス関連
│   │   ├── main.tf                   #    • ECS クラスター、タスク定義（Flask via Docker）、サービス定義
│   │   │                                （ALB と連携してコンテナを起動・スケーリング）
│   │   ├── variables.tf              #    • VPC ID、プライベートサブネット ID、ALB セキュリティグループ ID、ターゲットグループ ARN など
│   │   └── outputs.tf                #    • ECS クラスター名、サービス ARN、タスク定義 ARN など出力
│   │
│   ├── rds/                          # ─ RDS (MySQL/PostgreSQL など) 関連
│   │   ├── main.tf                   #    • DB サブネットグループ、DB インスタンス (エンジン・バージョン・サイズ・VPC セキュリティグループなど)
│   │   ├── variables.tf              #    • プライベートサブネット ID 群、DB インスタンスタイプ、ユーザー名/パスワード などの変数定義
│   │   └── outputs.tf                #    • RDS エンドポイント、ポート番号、セキュリティグループ ID など出力
│   │
│   └── s3/                           # ─ Terraform の状態管理用バックエンド（state）・tfstate 保存先を作る（※今回の構成であれば任意）
│       ├── main.tf                   #    • S3 バケット作成定義（tfstate 管理用）
│       ├── variables.tf              #    • バケット名やリージョン、オプション設定など
│       └── outputs.tf                #    • 作成した S3 バケット名・ARN など出力
│
├── myapp-python/                     # Webアプリ本体コード（Flask + Docker ベース）
│   ├── Dockerfile                    # ─ Python Flask アプリを動かすための Docker イメージビルド定義
│   ├── main.py                       # ─ Flask アプリ本体（簡単な Web API 例：Hello World など）
│   └── requirements.txt              # ─ Python パッケージ依存関係（Flask、boto3 など）
│
├── .gitignore                        # Git 管理時に無視するファイル・フォルダ設定
└── README.md                         # プロジェクト概要・実行手順などを記載したドキュメント
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
