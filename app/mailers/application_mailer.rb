# メーラー基底クラス
# 全てのメーラークラスの親クラス

class ApplicationMailer < ActionMailer::Base
  default from: "noreply@mitadake.com"  # 送信元アドレス
  layout "mailer"                   # メールテンプレートのレイアウト
end
