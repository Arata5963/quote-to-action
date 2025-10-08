# app/controllers/comments_controller.rb
class CommentsController < ApplicationController
  # ==== フィルター設定（共通処理）====

  # ログインしていないユーザーはコメントできないようにする
  before_action :authenticate_user!

  # 各アクションで、対象の投稿（@post）を特定する
  before_action :set_post

  # destroyアクション（削除）のみ、対象コメントを特定する
  before_action :set_comment, only: [:destroy]

  # destroyアクション（削除）のみ、自分のコメントか確認する
  before_action :check_owner, only: [:destroy]

  # ==== アクション定義 ====

  # コメント作成処理
  def create
    # 投稿(@post)に紐づくコメントを新しく作成（未保存）
    # → post_idが自動的にセットされる
    @comment = @post.comments.build(comment_params)

    # コメント投稿者（user_id）をログイン中のユーザーに設定
    @comment.user = current_user

    # バリデーションを通過すれば保存してリダイレクト
    if @comment.save
      redirect_to @post, notice: t('comments.create.success')
    else
      # 保存に失敗した場合は、エラーメッセージを表示して投稿詳細に戻す
      redirect_to @post, alert: @comment.errors.full_messages.first
    end
  end

  # コメント削除処理
  def destroy
    # 対象コメントを削除
    @comment.destroy

    # 投稿詳細ページにリダイレクトし、削除成功メッセージを表示
    redirect_to @post, notice: t('comments.destroy.success')
  end

  private  # === 以下はコントローラ内部でしか使わないメソッド ===

  # 投稿を取得
  def set_post
    # URLの :post_id から対象の投稿を取得
    @post = Post.find(params[:post_id])
  rescue ActiveRecord::RecordNotFound
    # 見つからない場合は一覧ページへリダイレクト
    redirect_to posts_path, alert: t('posts.not_found')
  end

  # コメントを取得（削除時のみ使用）
  def set_comment
    # 投稿(@post)に紐づくコメントの中から、URLの :id を持つコメントを探す
    @comment = @post.comments.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    # 見つからない場合は投稿詳細へリダイレクト
    redirect_to @post, alert: t('comments.not_found')
  end

  # 自分以外のコメントを削除できないようにする
  def check_owner
    unless @comment.user == current_user
      redirect_to @post, alert: t('comments.unauthorized')
    end
  end

  # Strong Parameters（安全に受け取るパラメータを指定）
  def comment_params
    # フォームから送信されるパラメータのうち、contentだけ許可
    params.require(:comment).permit(:content)
  end
end
