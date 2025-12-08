module Api
  module V1
    class ThemesController < BaseController
      skip_before_action :authenticate_api_key!, only: [ :index, :show ]

      def index
        themes = Theme.all.order(:name)
        render json: {
          data: themes.map { |t| serialize_theme(t) }
        }
      end

      def show
        theme = Theme.find_by!(slug: params[:id])
        render json: { data: serialize_theme(theme) }
      end

      private

      def serialize_theme(theme)
        {
          id: theme.id,
          name: theme.name,
          slug: theme.slug,
          description: theme.description,
          color: theme.color,
          posts_count: theme.posts_count
        }
      end
    end
  end
end
