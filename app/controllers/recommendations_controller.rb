# app/controllers/recommendations_controller.rb
class RecommendationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post

  def show
    @recommended_posts = @post.recommended_posts(limit: 3)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @post }
    end
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end
end
