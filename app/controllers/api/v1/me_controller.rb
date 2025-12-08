module Api
  module V1
    class MeController < BaseController
      def show
        render json: {
          data: {
            id: current_user.id,
            username: current_user.username,
            email: current_user.email,
            display_name: current_user.display_name,
            bio: current_user.bio,
            posts_count: current_user.posts_count,
            followers_count: current_user.followers_count,
            following_count: current_user.following_count
          }
        }
      end
    end
  end
end
