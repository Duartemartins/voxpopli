module Api
  module V1
    class VotesController < BaseController
      before_action :check_rate_limit!

      def create
        post = Post.find(params[:post_id])
        value = params[:value].to_i
        value = 1 unless value.in?([ -1, 1 ])

        vote = post.votes.find_by(user: current_user)

        if vote
          if vote.value == value
            vote.destroy
            render json: { data: { post_id: post.id, score: post.reload.score, voted: nil } }
          else
            vote.update!(value: value)
            render json: { data: { post_id: post.id, score: post.reload.score, voted: value } }
          end
        else
          vote = post.votes.create!(user: current_user, value: value)
          render json: { data: { post_id: post.id, score: post.reload.score, voted: value } }, status: :created
        end
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def destroy
        post = Post.find(params[:post_id])
        vote = post.votes.find_by!(user: current_user)
        vote.destroy
        render json: { data: { post_id: post.id, score: post.reload.score, voted: nil } }
      end
    end
  end
end
