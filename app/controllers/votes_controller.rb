class VotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post

  def create
    value = params[:value].to_i
    value = 1 unless value.in?([ -1, 1 ])

    @vote = @post.votes.find_by(user: current_user)

    respond_to do |format|
      if @vote
        # Change vote or remove if same value
        if @vote.value == value
          @vote.destroy
          @vote = nil
        else
          @vote.update(value: value)
        end
      else
        @vote = @post.votes.create(user: current_user, value: value)
      end

      @post.reload
      format.turbo_stream
      format.html { redirect_back fallback_location: timeline_path }
    end
  end

  def destroy
    @vote = @post.votes.find_by(user: current_user)
    @vote&.destroy
    @post.reload

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: timeline_path }
    end
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end
end
