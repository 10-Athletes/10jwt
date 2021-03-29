class SportsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
      @sports = Sport.all.as_json
      if @sports
        render json: {
          sports: @sports,
        }
      else
        render json: {
          status: 500,
          errors: ['no sports found']
        }
      end
  end

  def show
      @sport = Sport.find(params[:id])
     if @sport
        render json: {
          sport: @sport
        }
      else
        render json: {
          status: 500,
          errors: ['sport not found']
        }
      end
    end


  def create
    @sport=Sport.new(sport_params)
    if @sport.save
      render json: {
        status: :created,
        sport: @sport
      }
    else
      render json: {
        status: 500,
        errors: @sport.errors.full_messages
      }
    end
  end

  def update
    @sport = Sport.find(params[:id])
    alreadyAdded = false
    @sport["participants"].each do |participant|
      if participant["id"] == params["newUserInSport"]["id"]
        alreadyAdded = true
      end
    end
    unless alreadyAdded
      @sport["participants"].push(
        {
          id: params["newUserInSport"]["id"],
          name: params["newUserInSport"]["playerName"],
          username: params["newUserInSport"]["username"],
          rating: params["newUserInSport"]["rating"],
          opponents: []
        }
      )
    end
    @sport.save!
    render json: {status: 200}
  end

  private
  def sport_params
    params.require(:sport).permit(:name, :alternate_name, :newUserInSport)
  end
end
