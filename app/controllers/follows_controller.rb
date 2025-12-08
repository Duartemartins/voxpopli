class FollowsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def create
    current_user.follow(@user)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: user_path(@user) }
    end
  end

  def destroy
    current_user.unfollow(@user)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: user_path(@user) }
    end
  end

  private

  def set_user
    @user = User.find_by!(username: params[:user_username])
  end
end
