terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket-2025"   # ← S3バケット名
    key            = "dev/terraform.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
    # dynamodb_table = "your-lock-table"   # ← ロックは今回は不要なのでコメントアウトでOK
  }
}
