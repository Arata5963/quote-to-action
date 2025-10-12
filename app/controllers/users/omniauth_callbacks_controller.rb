# app/controllers/users/omniauth_callbacks_controller.rb
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # ※ Omniauth 2系 + omniauth-rails_csrf_protection を使う前提なので
  # verify_authenticity_token を無効化しない（state検証が働かなくなるため）

  def google_oauth2
    auth = request.env['omniauth.auth']
    unless auth
      redirect_to new_user_session_path, alert: 'Googleからの情報を取得できませんでした'
      return
    end

    begin
      @user = User.from_omniauth(auth)
    rescue => e
      Rails.logger.error("[OmniAuth] user save failed: #{e.class} #{e.message}")
      redirect_to new_user_session_path, alert: "ユーザー作成に失敗: #{e.message}"
      return
    end

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: 'Google') if is_navigational_format?
    else
      msg = @user.errors.full_messages.first.presence || '不明な理由で失敗しました'
      redirect_to new_user_session_path, alert: "Google認証に失敗しました: #{msg}"
    end
  end

  def failure
    type = request.env['omniauth.error.type']
    err  = request.env['omniauth.error']&.message ||
           params[:error_description] ||
           params[:message]
    Rails.logger.error("[OmniAuth][failure] type=#{type} message=#{err}")
    redirect_to root_path, alert: "Google認証に失敗しました（#{type}）"
  end
end
