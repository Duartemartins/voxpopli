module Api
  module V1
    class PostsController < BaseController
      before_action :check_rate_limit!

      def index
        sort = params[:sort].presence_in(%w[new voted]) || 'new'
        theme = Theme.find_by(slug: params[:theme])

        posts = Post.original.for_theme(theme)
        posts = sort == 'voted' ? posts.by_voted : posts.by_new
        posts = posts.includes(:user, :theme).page(params[:page]).per(25)

        render json: {
          data: posts.map { |p| serialize_post(p) },
          meta: { page: posts.current_page, total_pages: posts.total_pages }
        }
      end

      def show
        post = Post.find(params[:id])
        render json: { data: serialize_post(post) }
      end

      def create
        post = current_user.posts.build(post_params)

        if post.save
          render json: { data: serialize_post(post) }, status: :created
        else
          render json: { errors: post.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        post = current_user.posts.find(params[:id])
        post.destroy
        head :no_content
      end

      private

      def post_params
        permitted = params.permit(:body, :theme_id, :parent_id)
        # Convert blank foreign keys to nil to avoid FOREIGN KEY constraint violations
        permitted[:theme_id] = nil if permitted[:theme_id].blank?
        permitted[:parent_id] = nil if permitted[:parent_id].blank?
        permitted
      end

      def serialize_post(post)
        {
          id: post.id,
          body: post.body,
          score: post.score,
          votes_count: post.votes_count,
          replies_count: post.replies_count,
          theme: post.theme&.slug,
          user: { id: post.user.id, username: post.user.username },
          created_at: post.created_at.iso8601
        }
      end
    end
  end
end
