class TimelineController < ApplicationController
  before_action :authenticate_user!, except: [ :index ]

  def index
    @view = params[:view].presence_in(%w[new voted]) || "new"
    @theme = Theme.find_by(slug: params[:theme]) if params[:theme].present?
    @themes = Theme.all.order(:name)

    # Determine feed type (global vs following)
    default_feed = user_signed_in? && current_user.following.exists? ? "following" : "global"
    @feed_type = params[:feed].presence_in(%w[following global]) || default_feed
    
    # Force global if not signed in
    @feed_type = "global" unless user_signed_in?

    base_posts = if @feed_type == "following"
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
