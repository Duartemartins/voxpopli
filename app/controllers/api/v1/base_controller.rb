module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_api_key!

      private

      def authenticate_api_key!
        token = request.headers["Authorization"]&.split(" ")&.last
        @api_key = ApiKey.authenticate(token)

        unless @api_key
          render json: { error: "Invalid or missing API key" }, status: :unauthorized
        end
      end

      def current_user
        @api_key&.user
      end

      def check_rate_limit!
        if @api_key.rate_limit_exceeded?
          render json: { error: "Rate limit exceeded", retry_after: 1.hour.to_i }, status: :too_many_requests
        else
          @api_key.increment_usage!
        end
      end
    end
  end
end
