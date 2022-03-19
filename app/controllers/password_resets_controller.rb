class PasswordResetsController < ApplicationController
  def new
  end

  def validate
    @user = GlobalID::Locator.locate_signed(params[:token], purpose: "password_reset")
    if @user
      :ok
    else
      render json: {error: "expired/invalid"}, status: 401
    end
  end

  def create
    @user = User.find_by(email: params[:emailOrUsername])
    unless @user.present?
      @user = User.find_by(username: params[:emailOrUsername])
    end
    if @user.present?
      PasswordMailer.with(user: @user).reset.deliver_later
      :ok
    else
      :bad_request
    end
  end

  def edit
    @user = GlobalID::Locator.locate_signed(params[:token], purpose: "password_reset")
  end

  def update
    @user = GlobalID::Locator.locate_signed(params[:token], purpose: "password_reset")
    if @user
      puts @user.as_json
    end
    if @user.update(password: params[:password])
      :ok
    else
      render json: {error: "expired/invalid"}, status: 401
    end
  end

  private

  def password_params
    params.permit(:password, :token)
  end
end
