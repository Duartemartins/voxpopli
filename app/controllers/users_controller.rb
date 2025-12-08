class UsersController < ApplicationController
  before_action :set_user

  def show
    @posts = @user.posts.original.by_new.includes(:theme).page(params[:page]).per(25)
  end

  private

  def set_user
    @user = User.find_by!(username: params[:username])
  end
end
