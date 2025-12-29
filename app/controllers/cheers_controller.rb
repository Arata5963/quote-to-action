# app/controllers/cheers_controller.rb
class CheersController < ApplicationController
  # ==== フィルター設定（共通処理）====

  # ログインしていないユーザーは応援できないようにする
  before_action :authenticate_user!

  # 各アクションで、対象の投稿（@post）を特定する
  before_action :set_post

  # ==== アクション定義 ====

  # 応援作成処理
  def create
    # 既に応援済みの場合は何もしない
    if @post.cheered_by?(current_user)
      respond_to do |format|
        # 通常のHTMLリクエスト: 投稿一覧ページにリダイレクト
        format.html { redirect_to posts_path, alert: t("cheers.create.already_cheered") }

        # Turbo Streamリクエスト: 応援ボタン部分だけを更新（非同期）
        # "cheer_button_#{@post.id}" のIDを持つ要素を、_cheer_button.html.erb で置き換える
        format.turbo_stream { render turbo_stream: turbo_stream.replace("cheer_button_#{@post.id}", partial: "cheers/cheer_button", locals: { post: @post }) }
      end
      # 処理を終了（以降のコードは実行しない）
      return
    end

    # 投稿(@post)に紐づく応援を新しく作成（未保存）
    # user: current_user により、応援投稿者をログイン中のユーザーに設定
    @cheer = @post.cheers.build(user: current_user)

    # バリデーションを通過すれば保存
    if @cheer.save
      respond_to do |format|
        # 通常のHTMLリクエスト: 投稿一覧ページにリダイレクト、成功メッセージを表示
        format.html { redirect_to posts_path, notice: t("cheers.create.success") }

        # Turbo Streamリクエスト: 応援ボタン部分だけを更新（非同期）
        # 応援数が増え、ボタンが「応援済み」状態に変わる
        format.turbo_stream { render turbo_stream: turbo_stream.replace("cheer_button_#{@post.id}", partial: "cheers/cheer_button", locals: { post: @post }) }
      end
    else
      # 保存に失敗した場合
      respond_to do |format|
        # 通常のHTMLリクエスト: 投稿一覧ページにリダイレクト、エラーメッセージを表示
        format.html { redirect_to posts_path, alert: @cheer.errors.full_messages.first }

        # Turbo Streamリクエスト: 応援ボタン部分を元の状態で更新
        format.turbo_stream { render turbo_stream: turbo_stream.replace("cheer_button_#{@post.id}", partial: "cheers/cheer_button", locals: { post: @post }) }
      end
    end
  end

  # 応援削除処理
  def destroy
    # 自分の応援を探す
    # find_by は見つからない場合 nil を返す（find はエラーになる）
    @cheer = @post.cheers.find_by(user: current_user)

    # 応援が見つかった場合
    if @cheer
      # 応援を削除
      @cheer.destroy

      respond_to do |format|
        # 通常のHTMLリクエスト: 投稿一覧ページにリダイレクト、成功メッセージを表示
        format.html { redirect_to posts_path, notice: t("cheers.destroy.success") }

        # Turbo Streamリクエスト: 応援ボタン部分だけを更新（非同期）
        # 応援数が減り、ボタンが「応援」状態に戻る
        format.turbo_stream { render turbo_stream: turbo_stream.replace("cheer_button_#{@post.id}", partial: "cheers/cheer_button", locals: { post: @post }) }
      end
    else
      # 応援が見つからなかった場合（既に削除済み、または自分の応援ではない）
      respond_to do |format|
        # 通常のHTMLリクエスト: 投稿一覧ページにリダイレクト、エラーメッセージを表示
        format.html { redirect_to posts_path, alert: t("cheers.not_found") }

        # Turbo Streamリクエスト: 応援ボタン部分を現在の状態で更新
        format.turbo_stream { render turbo_stream: turbo_stream.replace("cheer_button_#{@post.id}", partial: "cheers/cheer_button", locals: { post: @post }) }
      end
    end
  end

  private  # === 以下はコントローラ内部でしか使わないメソッド ===

  # 投稿を取得
  def set_post
    # URLの :post_id から対象の投稿を取得
    # 例: /posts/5/cheers の場合、post_id は 5
    @post = Post.find(params[:post_id])
  rescue ActiveRecord::RecordNotFound
    # 投稿が見つからない場合（削除済み、または存在しないIDなど）
    # 投稿一覧ページにリダイレクトし、エラーメッセージを表示
    redirect_to posts_path, alert: t("posts.not_found")
  end
end
