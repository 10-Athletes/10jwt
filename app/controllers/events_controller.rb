class EventsController < ApplicationController

  def index
    @events = Event.last(10).as_json
    if @events
      render json: {
        events: @events
      }
    else
      render json: {
        status: 500,
        errors: ['no events found']
      }
    end
  end

  def getRating(player)
    rated = false
    player[:sports].each do |sport|
      if sport[:id] == event_params[:sport]
        rated = true
        rating = sport[:rating]
      end
    end
    rating = 0 unless rated
    return rating
  end

  def teamRatingCalc(teamRatings)
    count = 0
    rating = 0

    teamRatings.each do |playerRating|
      if playerRating != 0
        count = count + 1
        rating = playerRating + rating
      end
    end
    if count > 0
      rating = rating / count
    else
      rating = @team1Rating
    end
    rating
  end

  def create
    team1 = []
    team2 = []
    team1Ratings = []
    team2Ratings = []
    if event_params[:teammates].length > 0
      event_params[:teammates].each do |teammate|
        player = User.find_by(id: teammate[:id])
        rating = getRating(player)
        team1.push(teammate[:id])
        team1Ratings.push(rating)
      end
    else
      p1 = User.find_by(id: event_params[:p1ID])
      team1.push(p1)
      rating = getRating(p1)
      rating = event_params[:p1InitialRating] if rating == 0
      team1Ratings.push(rating)
    end
    @team1Rating = teamRatingCalc(team1Ratings)

    event_params[:opponents].each do |opponent|
      player = User.find_by(id: opponent[:id])
      rating = getRating(player)
      team2.push(opponent[:id])
      team2Ratings.push(rating)
    end

    team2Rating = teamRatingCalc(team2Ratings)

    # @p1=User.find_by(id: event_params[:p1ID])
    # @p2=User.find_by(id: event_params[:p2ID])
    # p1Initial = event_params[:p1InitialRating]
    # @p1[:sports].each do |sport|
    #   if sport[:id] == event_params[:sport]
    #     p1Initial = sport[:rating]
    #   end
    # end
    # p2Initial = p1Initial
    # @p2[:sports].each do |sport|
    #   if sport[:id] == event_params[:sport]
    #     p2Initial = sport[:rating]
    #   end
    # end
    event = {
      p1IDs: team1,
      team1InitialRating: @team1Rating,
      p2IDs: team2,
      team2InitialRating: team2Rating,
      winner: event_params[:winner],
      sport: event_params[:sport]
    }

    @event=Event.new(event)
    if @event.save
      render json: {
        status: :created,
        event: @event
      }

    else
      render json: {
        status: 500,
        errors: "failed to create event"
      }
    end
  end

  private
  def event_params
    params.require(:event).permit(:p1ID, :p1InitialRating, :p2ID, :p2InitialRating, :winner, :sport, :opponents, :teammates)
  end
end
