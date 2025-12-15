module Settings
  class InvitesController < ApplicationController
    before_action :authenticate_user!

    def index
      @invites = current_user.all_invite_codes
      @available_invites = current_user.invite_codes
      @can_generate = current_user.can_generate_invite_codes?
      @available_count = current_user.available_invite_codes_count
      @days_until_eligible = current_user.days_until_invite_eligibility
    end

    def create
      if current_user.can_generate_invite_codes?
        new_codes = current_user.generate_invite_codes!
        if new_codes.any?
          redirect_to settings_invites_path, notice: "Generated #{new_codes.count} new invite code(s)!"
        else
          redirect_to settings_invites_path, notice: "You already have the maximum number of invite codes."
        end
      else
        redirect_to settings_invites_path, alert: "You need to be a member for #{current_user.days_until_invite_eligibility} more day(s) before you can generate invite codes."
      end
    end
  end
end
