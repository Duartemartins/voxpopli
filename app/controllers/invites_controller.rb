class InvitesController < ApplicationController
  def new
    # Show form to enter invite code
  end

  def verify
    code = params[:code]&.strip&.upcase
    invite = Invite.available.find_by(code: code)

    if invite
      redirect_to new_user_registration_path(invite_code: code)
    else
      flash.now[:alert] = 'Invalid or expired invite code'
      render :new, status: :unprocessable_entity
    end
  end
end
