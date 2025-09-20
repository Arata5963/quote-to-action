# app/controllers/user_badges_controller.rb
class UserBadgesController < ApplicationController
    before_action :authenticate_user!
    
    def index
      @user_badges = current_user.user_badges.recent
      @total_badges = @user_badges.count
      @available_count = current_user.available_badges_count
    end
  end