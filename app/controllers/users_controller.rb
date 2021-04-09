class UsersController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    @users = User.all.as_json
    if @users
      render json: {
        users: @users
      }
    else
      render json: {
        status: 500,
        errors: ['no users found']
      }
    end
  end

  def create
    input = User.new(params.permit(:username, :password, :firstname, :lastname, :email))
    if(input.save)
      :ok
    else
      :bad_request
    end
  end

  def show
    @user = User.find(params[:id]).as_json
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

  def ratingChange()
  @p1Data = getInitialRatingData(1)
  @p2Data = getInitialRatingData(2)
  @p1Data.push(@p1Data[1])
  @p2Data.push(@p2Data[1])
  @winner = params["newEvent"]["winner"]

  amountChanged = (@p1Data[1] - @p2Data[1]).abs / 2 + 1
  if @p1Data[1] > @p2Data[1]
    higherRated = "1"
  else
    higherRated = "2"
  end

  if @winner == higherRated
    amountChanged = 0.05 / amountChanged
  else
    amountChanged = 0.05 * amountChanged
  end

  if @p1Data[0].length < 5
    p1Change = amountChanged * (6 - @p1Data[0].length)
  else
    p1Change = amountChanged
  end
  if @p2Data[0].length < 5
    p2Change = amountChanged * (6 - @p2Data[0].length)
  else
    p2Change = amountChanged
  end

  if @winner == "1"
    if @p1Data[1] + p1Change > 10 && @p1Data[0].length < 5
      @p1Data[1] = 10
    else
      if @p1Data[1] >= 10
        if @p1Data[1] >= 11
          p1Change = p1Change / 2
        elsif @p1Data[1] + p1Change / 2 > 11
          @p1Data[1] = (@p1Data[1] + p1Change / 2 - 11) / 2 + 11
          p1Change = 0
        end
        @p1Data[1] = @p1Data[1] + p1Change / 2
      elsif @p1Data[1] + p1Change > 10
        @p1Data[1] = (@p1Data[1] + p1Change - 10) / 2 + 10
      else
        @p1Data[1] = @p1Data[1] + p1Change
      end
    end
    if @p2Data[1] - p2Change < 1
      @p2Data[1] = 1
    else
      @p2Data[1] = @p2Data[1] - p2Change
    end
  else
    if @p2Data[1] + p2Change > 10 && @p2Data[0].length < 5
      @p2Data[1] = 10
    else
      if @p2Data[1] >= 10
        if @p2Data[1] >= 11
          p2Change = p2Change / 2
        elsif @p2Data[1] + p2Change / 2 > 11
          @p2Data[1] = (@p2Data[1] + p2Change / 2 - 11) / 2 + 11
          p2Change = 0
        end
        @p2Data[1] = @p2Data[1] + p2Change / 2
      elsif @p2Data[1] + p2Change > 10
        @p2Data[1] = (@p2Data[1] + p2Change - 10) / 2 + 10
      else
        @p2Data[1] = @p2Data[1] + p2Change
      end
    end
    if @p1Data[1] - p1Change < 1
      @p1Data[1] = 1
    else
      @p1Data[1] = @p1Data[1] - p1Change
    end
  end
  # @p1Data[1] = @p1Data[1]
  # @p2Data[1] = @p2Data[1]
end

def getInitialRatingData(playerNum)
  if playerNum == 1
    player = @p1
    opponent = @p2
    rating = params["newEvent"]["p1InitialRating"]
  elsif playerNum == 2
    player = @p2
    opponent = @p1
  end
  opponents = []
  player["sports"].each do |sport|
    if sport["id"] == @sportID
      opponentIncluded = false
      rating = sport["rating"]
      sport["opponents"].each do |opponentID|
        opponents.push(opponentID)
        opponentIncluded = true if opponentID == opponent["id"]
      end
      opponents.push(opponent["id"]) unless opponentIncluded
    end
  end
  if opponents.length == 0
    opponents.push(opponent["id"])
  end
  if !rating && playerNum == 2
    rating = @p1Data[1]
  end
  return [opponents, rating]
end

def updateAthlete(index, player)
  if player == 1
    opponentID = @p2ID
    data = @p1Data
  elsif player == 2
    opponentID = @p1ID
    data = @p2Data
  end
  sportIncluded = false
  official = false
  @athlete["participants"][index]["sports"].each do |sport|
    if sport["id"] == @sportID
      sport["rating"] = data[1]
      sport["opponents"] = data[0]
      sportIncluded = true
    end
    official = true if sport["opponents"].length >= 5
  end
  unless sportIncluded
    sportsArr = []
    insert_at = @athlete["participants"][index]["sports"].bsearch_index {|sport| sport["rating"] < data[1]}
     unless insert_at
       insert_at = @athlete["participants"][index]["sports"].length
     end
    @athlete["participants"][index]["sports"].each_with_index do |sport, i|
      if i == insert_at
        sportsArr.push({id: @sportID, rating: data[1], opponents: [opponentID]})
      end
      sportsArr.push(sport)
      # For timing purposes I need to have this line here. This is the case where the sport goes into the
      # last position in the array as nothing is lower rating than it.
      if i == insert_at - 1 && i == @athlete["participants"][index]["sports"].length - 1
        sportsArr.push({id: @sportID, rating: data[1], opponents: [opponentID]})
      end
    end

    @athlete["participants"][index]["sports"] = sportsArr
    # .insert(insert_at, {id: @sportID, rating: data[1], opponents: [opponentID]})
  end
  error = ""
  rating = 0
  count = 0
  if official
    @athlete["participants"][index]["official"] = true
    @athlete["participants"][index]["sports"].each_with_index do |sport, i|
      thisRating = data[1]
      thisOpponents = data[0]
      unless i == insert_at
        thisRating = sport["rating"]
        thisOpponents = sport["opponents"]
      end
      if thisOpponents.length >= 5
        thisRating = data[1]
        if count == 0
          rating = thisRating
        elsif count < 11
          rating = rating + thisRating / 100 * (11 - i)
        else
          rating = rating + thisRating / 1000
        end
        count += 1
      end
    end
  else
    @athlete["participants"][index]["official"] = false
    @athlete["participants"][index]["sports"].each_with_index do |sport, i|
      thisRating = data[1]
      unless i == insert_at
        thisRating = sport["rating"]
      end
      if i == 0
        rating = thisRating
      elsif i < 11
        rating = rating + thisRating / 100 * (11 - i)
      else
        rating = rating + thisRating / 1000
      end
    end
  end
  # rating = @athlete["participants"][index]["sports"]

  @athlete["participants"][index]["rating"] = rating
end

def updateSport
  alreadyAdded = false
  @user.sports.each do |sport|
    if sport["id"] == params["newSport"]["id"]
      alreadyAdded = true
    end
  end
  unless alreadyAdded
    @user["sports"].push(
      {
        id: params["newSport"]["id"],
        name: params["newSport"]["name"],
        rating: params["newSport"]["rating"],
        opponents: []
      })
    end
  @user.save!
  render json: {status: 200}
end


def update
  @user = User.find(params[:id])
  if params.has_key?("newEvent")
    @athlete = Sport.find(10)
    @p1ID = params["newEvent"]["p1ID"]
    @p2ID = params["newEvent"]["p2ID"]
    @p1Initial = params["newEvent"]["p1InitialRating"]
    p1Name = params["newEvent"]["p1Name"]
    p1Username = params["newEvent"]["p1Username"]
    p2Name = params["newEvent"]["p2Name"]
    p2Username = params["newEvent"]["p2Username"]
    @sportID = params["newEvent"]["sport"]
    @p1 = User.find(@p1ID)
    @p2 = User.find(@p2ID)
    ratingChange()
    p1Index, p2Index = -1, -1
    @athlete["participants"].each_with_index do |participant, index|
      if participant["id"] == @p1ID
        p1Index = index
      elsif participant["id"] == @p2ID
        p2Index = index
      end
    end
    if p1Index < 0
      p1Index = @athlete["participants"].length
      @athlete["participants"].push({
        id: @p1ID,
        name: p1Name,
        username: p1Username,
        rating: @p1Data[1],
        official: false,
        sports: [{
          id: @sportID,
          rating: @p1Data[1],
          opponents: @p1Data[0]
        }]
      })
    else
      updateAthlete(p1Index, 1)
    end
    if p2Index < 0
      p2Index = @athlete["participants"].length
      @athlete["participants"].push({
        id: @p2ID,
        name: p2Name,
        username: p2Username,
        rating: @p2Data[1],
        official: false,
        sports: [{
          id: @sportID,
          rating: @p2Data[1],
          opponents: @p2Data[0]
        }]
      })
    else
      updateAthlete(p2Index, 2)
    end
    sports = []
    sportIncluded = false
    athleteIncluded = false
    @p1["sports"].each do |sport|
      if @sportID == sport["id"]
        sportIncluded = true
        sport["rating"] = @p1Data[1]
        sport["opponents"] = @p1Data[0]
      end
      if sport["id"] == 10
        athleteIncluded = true
        sport["rating"] = @athlete["participants"][p1Index]["rating"]
        sport["sports"] = @athlete["participants"][p1Index]["sports"]
        sport["official"] = @athlete["participants"][p1Index]["official"]
      end
      sports.push(sport)
    end
    unless sportIncluded
      sports.push({
        id: @sportID,
        name: params["newEvent"]["sportName"],
        rating: @p1Data[1],
        opponents: @p1Data[0]
      })
    end
    unless athleteIncluded
      sports.push({
        id: 10,
        name: "Athlete",
        rating: @p1Data[1],
        official: false,
        sports: [{
          id: @sportID,
          rating: @p1Data[1],
          opponents: @p1Data[0]
        }]
      })
    end
    @p1["sports"] = sports
    @p1["events"].push({
      sport: @sportID,
      p1ID: @p1ID,
      p1InitialRating: @p1Data[2],
      p2ID: @p2ID,
      p2InitialRating: @p2Data[2],
      winner: @winner,
      created: Time.now
      })
    @p1.save!
    sports = []
    sportIncluded = false
    athleteIncluded = false
    @p2["sports"].each do |sport|
      if @sportID == sport["id"]
        sportIncluded = true
        sport["rating"] = @p2Data[1]
        sport["opponents"] = @p2Data[0]
      end
      if sport["id"] == 10
        athleteIncluded = true
        sport["rating"] = @athlete["participants"][p2Index]["rating"]
        sport["sports"] = @athlete["participants"][p2Index]["sports"]
        sport["official"] = @athlete["participants"][p2Index]["official"]
      end
      sports.push(sport)
    end
    unless sportIncluded
      sports.push({
        id: @sportID,
        name: params["newEvent"]["sportName"],
        rating: @p2Data[1],
        opponents: @p2Data[0]
      })
    end
    unless athleteIncluded
      sports.push({
        id: 10,
        name: "Athlete",
        rating: @p2Data[1],
        official: false,
        sports: [{
          id: @sportID,
          rating: @p2Data[1],
          opponents: @p2Data[0]
        }]
      })
    end
    @p2["sports"] = sports
    @p2["events"].push({
      sport: @sportID,
      p1ID: @p1ID,
      p1InitialRating: @p1Data[2],
      p2ID: @p2ID,
      p2InitialRating: @p2Data[2],
      winner: @winner,
      created: Time.now
      })
    @p2.save!
    @athlete.save!
    @sport = Sport.find(@sportID)
    p1Updated = false
    p2Updated = false
    @sport.participants.each do |participant|
      if participant["id"] == @p1ID
        p1Updated = true
        participant["rating"] = @p1Data[1]
        participant["opponents"] = @p1Data[0]
      elsif participant["id"] == @p2ID
        p2Updated = true
        participant["rating"] = @p2Data[1]
        participant["opponents"] = @p2Data[0]
      end
    end
    unless p1Updated
      @sport["participants"].push({
        id: @p1ID,
        name: p1Name,
        username: p1Username,
        rating: @p1Data[1],
        opponents: @p1Data[0],
        })
    end
    unless p2Updated
      @sport["participants"].push({
        id: @p2ID,
        name: p2Name,
        username: p2Username,
        rating: @p2Data[1],
        opponents: @p2Data[0],
        })
    end
    @sport.save!
    render json: {status: 200, updated: true}
  elsif params.has_key?("newSport")
    updateSport()
  end
  @user
end

private

  def user_params
    params.require(:user).permit(:username, :email, :firstname, :lastname, :password, :password_confirmation, :newEvent, :rating, :newSport)
  end
end
