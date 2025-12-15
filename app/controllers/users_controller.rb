class UsersController < ApplicationController
  before_action :set_user
  before_action :authenticate_user!, only: [ :edit, :update ]
  before_action :authorize_user!, only: [ :edit, :update ]

  def show
    @posts = @user.posts.original.by_new.includes(:theme).page(params[:page]).per(25)
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to user_path(@user.username), notice: "Profile updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find_by!(username: params[:username])
  end

  def authorize_user!
    unless @user == current_user
      redirect_to user_path(@user.username), alert: "You can only edit your own profile"
    end
  end

  def user_params
    params.require(:user).permit(:display_name, :bio, :website, :avatar)
  end
end
