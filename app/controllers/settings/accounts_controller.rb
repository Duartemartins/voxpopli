module Settings
  class AccountsController < ApplicationController
    before_action :authenticate_user!

    def show
    end

    def destroy
      current_user.destroy
      sign_out current_user
      redirect_to root_path, notice: 'Your account has been permanently deleted'
    end
  end
end
