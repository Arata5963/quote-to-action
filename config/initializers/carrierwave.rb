CarrierWave.configure do |config|
  # 画像の保存先を指定
  # :file → ローカル保存、:fog → S3などクラウド保存
  config.storage = :fog

  # fogライブラリのAWSサポートを利用する
  config.fog_provider = "fog/aws"

  # AWSに接続するための認証情報を設定
  config.fog_credentials = {
    # AWSを利用する場合は固定で "AWS"
    provider:              "AWS",
    # AWSアクセスキーID（環境変数から読み込み）
    aws_access_key_id:     ENV["AWS_ACCESS_KEY_ID"],
    # AWSシークレットキー（環境変数から読み込み）
    aws_secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"],
    # S3バケットを作成したリージョン（例: ap-southeast-2）
    region:                ENV["AWS_REGION"]
  }

  # 保存先となるS3バケット名（環境変数に設定したもの）
  config.fog_directory = ENV["AWS_BUCKET"]

  # アップロードしたファイルを「公開」にする設定
  # true → 誰でもアクセス可能
  # false → 署名付きURLでのみアクセス可能
  config.fog_public = false

  # ACL設定を無効化（Object Ownership設定との競合を防ぐ）
  config.fog_attributes = {}
end
