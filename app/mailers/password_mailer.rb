class PasswordMailer < ApplicationMailer
  def reset
    @token = params[:user].to_sgid(expires_in: 30.minutes, purpose: "password_reset").to_s
    mail to: params[:user].email
  end
end
