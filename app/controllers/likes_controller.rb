# app/controllers/likes_controller.rb
class LikesController < ApplicationController
  # ==== フィルター設定（共通処理）====

  # ログインしていないユーザーはいいねできないようにする
  before_action :authenticate_user!

  # 各アクションで、対象の投稿（@post）を特定する
  before_action :set_post

  # ==== アクション定義 ====

  # いいね作成処理
  def create
    # 既にいいね済みの場合は何もしない
    if @post.liked_by?(current_user)
      respond_to do |format|
        # 通常のHTMLリクエスト: 投稿一覧ページにリダイレクト
        format.html { redirect_to posts_path, alert: t("likes.create.already_liked") }

        # Turbo Streamリクエスト: いいねボタン部分だけを更新（非同期）
        # "like_button_#{@post.id}" のIDを持つ要素を、_like_button.html.erb で置き換える
        format.turbo_stream { render turbo_stream: turbo_stream.replace("like_button_#{@post.id}", partial: "likes/like_button", locals: { post: @post }) }
      end
      # 処理を終了（以降のコードは実行しない）
      return
    end

    # 投稿(@post)に紐づくいいねを新しく作成（未保存）
    # user: current_user により、いいね投稿者をログイン中のユーザーに設定
    @like = @post.likes.build(user: current_user)

    # バリデーションを通過すれば保存
    if @like.save
      respond_to do |format|
        # 通常のHTMLリクエスト: 投稿一覧ページにリダイレクト、成功メッセージを表示
        format.html { redirect_to posts_path, notice: t("likes.create.success") }

        # Turbo Streamリクエスト: いいねボタン部分だけを更新（非同期）
        # いいね数が増え、ボタンが「いいね済み」状態に変わる
        format.turbo_stream { render turbo_stream: turbo_stream.replace("like_button_#{@post.id}", partial: "likes/like_button", locals: { post: @post }) }
      end
    else
      # 保存に失敗した場合
      respond_to do |format|
        # 通常のHTMLリクエスト: 投稿一覧ページにリダイレクト、エラーメッセージを表示
        format.html { redirect_to posts_path, alert: @like.errors.full_messages.first }

        # Turbo Streamリクエスト: いいねボタン部分を元の状態で更新
        format.turbo_stream { render turbo_stream: turbo_stream.replace("like_button_#{@post.id}", partial: "likes/like_button", locals: { post: @post }) }
      end
    end
  end

  # いいね削除処理
  def destroy
    # 自分のいいねを探す
    # find_by は見つからない場合 nil を返す（find はエラーになる）
    @like = @post.likes.find_by(user: current_user)

    # いいねが見つかった場合
    if @like
      # いいねを削除
      @like.destroy

      respond_to do |format|
        # 通常のHTMLリクエスト: 投稿一覧ページにリダイレクト、成功メッセージを表示
        format.html { redirect_to posts_path, notice: t("likes.destroy.success") }

        # Turbo Streamリクエスト: いいねボタン部分だけを更新（非同期）
        # いいね数が減り、ボタンが「いいね」状態に戻る
        format.turbo_stream { render turbo_stream: turbo_stream.replace("like_button_#{@post.id}", partial: "likes/like_button", locals: { post: @post }) }
      end
    else
      # いいねが見つからなかった場合（既に削除済み、または自分のいいねではない）
      respond_to do |format|
        # 通常のHTMLリクエスト: 投稿一覧ページにリダイレクト、エラーメッセージを表示
        format.html { redirect_to posts_path, alert: t("likes.not_found") }

        # Turbo Streamリクエスト: いいねボタン部分を現在の状態で更新
        format.turbo_stream { render turbo_stream: turbo_stream.replace("like_button_#{@post.id}", partial: "likes/like_button", locals: { post: @post }) }
      end
    end
  end

  private  # === 以下はコントローラ内部でしか使わないメソッド ===

  # 投稿を取得
  def set_post
    # URLの :post_id から対象の投稿を取得
    # 例: /posts/5/likes の場合、post_id は 5
    @post = Post.find(params[:post_id])
  rescue ActiveRecord::RecordNotFound
    # 投稿が見つからない場合（削除済み、または存在しないIDなど）
    # 投稿一覧ページにリダイレクトし、エラーメッセージを表示
    redirect_to posts_path, alert: t("posts.not_found")
  end
end
