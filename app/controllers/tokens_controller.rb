class TokensController < ApplicationController
  def create
    user = User.find_by(username: params[:username])
    if user&.authenticate(params[:password])
      render json: {
        jwt: encode_token({id: user.id, username: user.username, sports: user.sports, events: user.events})
      }
    else
      head :not_found
    end
  end

  private
  def encode_token(payload={})
    JWT.encode(payload, Rails.application.secrets.secret_key_base)
  end
end
