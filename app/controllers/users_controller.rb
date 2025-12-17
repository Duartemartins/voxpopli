class UsersController < ApplicationController
  before_action :set_user, except: [ :dismiss_quest ]
  before_action :authenticate_user!, only: [ :edit, :update, :dismiss_quest ]
  before_action :authorize_user!, only: [ :edit, :update ]

  def show
    @posts = @user.posts.original.by_new.includes(:theme).page(params[:page]).per(25)
  end

  def edit
  end

  def update
    # Handle launched_products_attributes separately
    if params[:user][:launched_products_attributes].present?
      products = params[:user][:launched_products_attributes].values.map do |p|
        # Skip if marked for destruction or empty
        next if p[:_destroy] == "1" || p[:_destroy] == true
        next if p[:name].blank? && p[:url].blank?
        {
          "name" => p[:name],
          "url" => p[:url],
          "description" => p[:description],
          "mrr" => p[:mrr].present? ? p[:mrr].to_i : nil,
          "revenue_confirmed" => p[:revenue_confirmed] == "1"
        }
      end.compact
      @user.launched_products = products
    end

    if @user.update(user_params)
      redirect_to user_path(@user.username), notice: "Profile updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def dismiss_quest
    current_user.update(quest_dismissed: true)

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("onboarding_quest") }
      format.html { redirect_back fallback_location: root_path }
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
    params.require(:user).permit(:display_name, :bio, :website, :avatar, :tagline, :github_username, :skills_list, :looking_for)
  end
end
