# Adds the REGISTRATION_ENABLED kill switch (config.x.registration_enabled,
# see config/application.rb) on top of Devise's default behaviour. Signing
# in, editing your account, and everything else Devise handles is untouched.
class Users::RegistrationsController < Devise::RegistrationsController
  before_action :check_registration_enabled, only: [ :new, :create ]

  private

  def check_registration_enabled
    return if Rails.application.config.x.registration_enabled

    redirect_to new_user_session_path, alert: "Registration is currently closed."
  end
end
