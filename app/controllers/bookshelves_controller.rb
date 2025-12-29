class BookshelvesController < ApplicationController
  def show
    if params[:id]
      @user = User.find(params[:id])
      @is_own_page = user_signed_in? && @user == current_user

      if @is_own_page
        redirect_to bookshelf_path
        return
      end
    else
      authenticate_user!
      @user = current_user
      @is_own_page = true
    end

    # 表示する年月を設定（デフォルトは現在月）
    @year = (params[:year] || Date.current.year).to_i
    @month = (params[:month] || Date.current.month).to_i
    @current_date = Date.new(@year, @month, 1)

    # 月の開始日と終了日
    start_date = @current_date.beginning_of_month
    end_date = @current_date.end_of_month

    # その月の達成済み投稿を取得
    achieved_posts = @user.posts
                          .where.not(achieved_at: nil)
                          .where(achieved_at: start_date.beginning_of_day..end_date.end_of_day)
                          .order(achieved_at: :asc)

    # 日付ごとにグループ化
    @posts_by_date = achieved_posts.group_by { |post| post.achieved_at.to_date }

    # 月の全日付リスト
    @dates = (start_date..end_date).to_a

    # 総達成数（全期間）
    @total_count = @user.posts.where.not(achieved_at: nil).count
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: t("users.not_found")
  end
end
