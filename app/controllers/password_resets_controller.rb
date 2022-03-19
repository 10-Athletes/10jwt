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
    token = convertToken()
    @user = GlobalID::Locator.locate_signed(token, purpose: "password_reset")
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

  #remove '%3D that was replacing equals in tokens'
  def convertToken
    token = ""
    counter = 0
    params[:token].each_char.with_index do |char, i|
      if i < params[:token].length - 2 && char == '%' && params[:token][i+1] == '3' && params[:token][i+2] == 'D'
        token += '='
        counter = 2
      elsif counter == 0
        counter -= 1
      else
        token += char
      end
    end
    return token
  end
end
