class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :set_post, only: [:show, :destroy]

  def show
    @replies = @post.replies.includes(:user).by_new
  end

  def create
    @post = current_user.posts.build(post_params)

    respond_to do |format|
      if @post.save
        format.turbo_stream
        format.html { redirect_to timeline_path, notice: 'Post created' }
      else
        format.html { redirect_to timeline_path, alert: @post.errors.full_messages.join(', ') }
      end
    end
  end

  def destroy
    if @post.user == current_user
      @post.destroy
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.remove(@post) }
        format.html { redirect_to timeline_path, notice: 'Post deleted' }
      end
    else
      redirect_to timeline_path, alert: 'Not authorized'
    end
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    permitted = params.require(:post).permit(:body, :theme_id, :parent_id)
    # Convert blank foreign keys to nil to avoid FOREIGN KEY constraint violations
    permitted[:theme_id] = nil if permitted[:theme_id].blank?
    permitted[:parent_id] = nil if permitted[:parent_id].blank?
    permitted
  end
end
