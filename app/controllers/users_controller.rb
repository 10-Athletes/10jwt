class UsersController < ApplicationController
  def create
    input = User.new(params.permit(:username, :password, :firstname, :lastname, :email))
    if(input.save)
      :ok
    else
      :bad_request
    end
  end
end
