module Settings
  class ApiKeysController < ApplicationController
    before_action :authenticate_user!
    before_action :set_api_key, only: [ :destroy ]

    def index
      @api_keys = current_user.api_keys.order(created_at: :desc)
    end

    def create
      @api_key = current_user.api_keys.build(api_key_params)

      if @api_key.save
        flash[:api_key] = @api_key.raw_key
        redirect_to settings_api_keys_path, notice: "API key created successfully. Copy it now - it won't be shown again!"
      else
        @api_keys = current_user.api_keys.order(created_at: :desc)
        render :index, status: :unprocessable_entity
      end
    end

    def destroy
      @api_key.destroy
      redirect_to settings_api_keys_path, notice: "API key revoked"
    end

    private

    def set_api_key
      @api_key = current_user.api_keys.find(params[:id])
    end

    def api_key_params
      params.require(:api_key).permit(:name)
    end
  end
end
