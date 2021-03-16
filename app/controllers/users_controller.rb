class UsersController < ApplicationController
  def create
    input = User.new(params.permit(:username, :password, :firstname, :lastname, :email))
    if(input.save)
      :ok
    else
      :bad_request
    end
  end

  def show
    @user = User.find(params[:id])
    if @user
       render json: {
         user: @user
       }
    else
       render json: {
         status: 500,
         errors: ['user not found']
       }
    end
  end
end
