class TimelineController < ApplicationController
  before_action :authenticate_user!, except: [ :index ]

  def index
    @view = params[:view].presence_in(%w[new voted]) || "new"
    @theme = Theme.find_by(slug: params[:theme]) if params[:theme].present?

    base_posts = if user_signed_in?
      current_user.timeline
    else
      Post.original
    end

    base_posts = base_posts.for_theme(@theme)

    @posts = case @view
    when "new"
      base_posts.by_new
    when "voted"
      base_posts.by_voted
    end.includes(:user, :theme).page(params[:page]).per(25)
  end
end
