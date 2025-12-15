class RegistrationsController < Devise::RegistrationsController
  before_action :validate_invite_code, only: [ :new, :create ]
  before_action :check_honeypot, only: [ :create ]

  def new
    @invite = Invite.available.find_by!(code: params[:invite_code])
    super
  end

  def create
    @invite = Invite.available.find_by!(code: params[:user][:invite_code])
    super do |user|
      if user.persisted?
        @invite.use!(user)
      end
    end
  end

  def destroy
    current_user.destroy
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    set_flash_message! :notice, :destroyed
    yield if block_given?
    respond_with_navigational(resource) { redirect_to after_sign_out_path_for(resource_name) }
  end

  private

  def validate_invite_code
    code = params[:invite_code] || params.dig(:user, :invite_code)
    unless code.present? && Invite.available.exists?(code: code)
      redirect_to join_path, alert: "Valid invite code required to register. You can also pay $5 to register."
    end
  end

  def check_honeypot
    # Honeypot field - should be empty (bots often fill hidden fields)
    if params[:user][:website_url].present?
      redirect_to root_path, alert: "Registration failed"
    end
  end
end
