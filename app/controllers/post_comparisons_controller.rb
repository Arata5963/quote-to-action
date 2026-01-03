# app/controllers/post_comparisons_controller.rb
class PostComparisonsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_source_post
  before_action :authorize_owner!
  before_action :set_comparison, only: [:destroy]

  def create
    @comparison = @source_post.outgoing_comparisons.build(comparison_params)

    if @comparison.save
      redirect_to @source_post, notice: "比較対象を追加しました"
    else
      redirect_to @source_post, alert: @comparison.errors.full_messages.join(", ")
    end
  end

  def destroy
    @comparison.destroy
    redirect_to @source_post, notice: "比較対象を削除しました"
  end

  private

  def set_source_post
    @source_post = Post.find(params[:post_id])
  end

  def set_comparison
    @comparison = @source_post.outgoing_comparisons.find(params[:id])
  end

  def authorize_owner!
    unless @source_post.user == current_user
      redirect_to @source_post, alert: "他のユーザーの投稿には比較を追加できません"
    end
  end

  def comparison_params
    params.require(:post_comparison).permit(:target_post_id, :reason)
  end
end
