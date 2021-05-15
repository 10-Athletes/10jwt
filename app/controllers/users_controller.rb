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
    team1 = params["newEvent"]["teammates"]
    team2 = params["newEvent"]["opponents"]
    team1Rating = 0
    team2Rating = 0
    team1Opponents = []
    team1Ratings = []
    team2Opponents = []
    team2Ratings = []
    numRated = 0
    sportIndeces = []
    team1.each_with_index do |player, idx|
      currentPlayer = User.find(player.id)
      updatedPlayer = currentPlayer.getInitialRatingData(1, currentPlayer)
      @team1.push(updatedPlayer[0])
      if idx == 0 && updatedPlayer[2] == 0
        p1InitialRating = params["newEvent"]["p1InitialRating"]
        team1Ratings.push(p1InitialRating)
        team1Rating += p1InitialRating
        numRated += 1
      else
        team1Ratings.push(updatedPlayer[2])
      end
      if updatedPlayer[2] > 0
        numRated += 1
      end
      sportIndeces.push(updatedPlayer[1])
    end
      team1Rating = team1Rating / numRated
    numRated = 0
    team2.each do |player|
      currentPlayer = User.find(player.id)
      updatedPlayer = currentPlayer.getInitialRatingData(2, currentPlayer)
      @team2.push(updatedPlayer)
      team2Rating += updatedPlayer[2]
      team2Ratings.push(updatedPlayer[2])
      if updatedPlayer[2] > 0
        numRated += 1
      end
      sportIndeces.push(updatedPlayer[1])
    end
    if numRated == 0
      team2Rating = team1Rating
    else
      team2Rating = team2Rating / numRated
    end

  @winner = params["newEvent"]["winner"]

  amountChanged = (team2Rating - team1Rating).abs / 2 + 1
  if team1Rating > team2Rating
    higherRated = "1"
  else
    higherRated = "2"
  end

  if @winner == higherRated
    amountChanged = 0.05 / amountChanged
  else
    amountChanged = 0.05 * amountChanged
  end
  #TODO: refactor so I'm not duplicating 20+ lines of code
  if winner == "1"
    won = true
  else
    won = false
  end
  #TODO fix numOpponents (sportIndex needs tracking here)
  # and need to find quantity of events of
  # that specific sport
  @team1.each_with_index do |player, index|
    numberOfOpponents = player["sports"][sportIndeces[index]].length
    # TODO: MAKE THIS WAY MORE EFFICIENT,
    # MAYBE DEFINE A VARIABLE STORED IN PLAYER{sport}
    # MAYBE STORE EVENTS WITHIN PLAYER{sport}
    numberOfGames = 0
    player["events"].each do |event|
      if event["sport"] == @sportID
        numberOfGames += 1
      end
    end
    numberOfGames += 1
    if numberOfOpponents > numberOfGames
      modifierVariable = numberOfGames
    else
      modifierVariable = numberOfOpponents
    end
    if modifierVariable < 5
      change = amountChanged * (6 - modifierVariable)
    else
      change = amountChanged
    end
    if team1Ratings[index] == 0
      rating = team1Rating
    else
      rating = team1Ratings[index]
    end
    rating = calculate(player, rating, change, won, modifierVariable)
  end
  if "winner" != "1"
    won = true
  else
    won = false
  end

  @team2.each_with_index do |player, index|
    numberOfOpponents = player.opponents.length + team2Opponents[index]
    numberOfGames = player.events.length + 1
    if numberOfOpponents > numberOfGames
      modifierVariable = numberOfGames
    else
      modifierVariable = numberOfOpponents
    end
    if modifierVariable < 5
      change = amountChanged * (6 - modifierVariable)
    else
      change = amountChanged
    end
    if team2Ratings[index] == 0
      rating = team2Rating
    else
      rating = team2Ratings[index]
    end
    rating = calculate(player, rating, change, won, modifierVariable)
  end
  # if @p2Data[0].length < 5
  #   p2Change = amountChanged * (6 - @p2Data[0].length)
  # else
  #   p2Change = amountChanged
  # end

  # if @winner == "1"
  #   if @p1Data[1] + p1Change > 10 && @p1Data[0].length < 5
  #     @p1Data[1] = 10
  #   else
  #     if @p1Data[1] >= 10
  #       if @p1Data[1] >= 11
  #         p1Change = p1Change / 2
  #       elsif @p1Data[1] + p1Change / 2 > 11
  #         @p1Data[1] = (@p1Data[1] + p1Change / 2 - 11) / 2 + 11
  #         p1Change = 0
  #       end
  #       @p1Data[1] = @p1Data[1] + p1Change / 2
  #     elsif @p1Data[1] + p1Change > 10
  #       @p1Data[1] = (@p1Data[1] + p1Change - 10) / 2 + 10
  #     else
  #       @p1Data[1] = @p1Data[1] + p1Change
  #     end
  #   end
  #   if @p2Data[1] - p2Change < 1
  #     @p2Data[1] = 1
  #   else
  #     @p2Data[1] = @p2Data[1] - p2Change
  #   end
  # else
  #   if @p2Data[1] + p2Change > 10 && @p2Data[0].length < 5
  #     @p2Data[1] = 10
  #   else
  #     if @p2Data[1] >= 10
  #       if @p2Data[1] >= 11
  #         p2Change = p2Change / 2
  #       elsif @p2Data[1] + p2Change / 2 > 11
  #         @p2Data[1] = (@p2Data[1] + p2Change / 2 - 11) / 2 + 11
  #         p2Change = 0
  #       end
  #       @p2Data[1] = @p2Data[1] + p2Change / 2
  #     elsif @p2Data[1] + p2Change > 10
  #       @p2Data[1] = (@p2Data[1] + p2Change - 10) / 2 + 10
  #     else
  #       @p2Data[1] = @p2Data[1] + p2Change
  #     end
  #   end
  #   if @p1Data[1] - p1Change < 1
  #     @p1Data[1] = 1
  #   else
  #     @p1Data[1] = @p1Data[1] - p1Change
  #   end
  # end
  # @p1Data[1] = @p1Data[1]
  # @p2Data[1] = @p2Data[1]
end

def calculate(player, initialRating, change, yourTeamWon, modifier)
  if yourTeamWon
    if initialRating + change > 10 && modifier < 5
      rating = 10
    else
      if initialRating >= 10
        if initialRating >= 11
          change = change / 2
        elsif initialRating + change / 2 > 11
          rating = (initialRating + change / 2 - 11) / 2 + 11
          change = 0
        end
        rating = initialRating + change / 2
      elsif initialRating + change > 10
        rating = (initialRating + change - 10) / 2 + 10
      else
        rating = initialRating + change
      end
    end
  else
    if initialRating - change < 1
      rating = 1
    else
      rating = initialRating - change
    end
  end
  return rating
end

def getInitialRatingData(teamNum, player)
  if teamNum == 1
    currentGameOpponents = params["newEvent"]["opponents"]
  elsif teamNum == 2
    currentGameOpponents =  params["newEvent"]["teammates"]
  end
  rating = 0
  sportFound = false
  sportIndex = -1
  player["sports"].each_with_index do |sport, idx|
    if sport["id"] == @sportID
      sportFound = true
      sportIndex = idx
      rating = sport["rating"]
      currentGameOpponents.each do |opponent|
        opponentIncluded = false
        sport["opponents"].each do |opponentID|
          opponentIncluded = true if opponentID == opponent["id"]
        end
        sport["opponents"].push(opponent["id"]) unless opponentIncluded
      end
    end
  end
  unless sportFound
    sportName = Sport.find(@sportID)["name"]
    currentGameOpponents.each do |opponent|
      playerOpponents.push(opponent["id"])
    end
    sportIndex = player["sports"].length
    player["sports"].push(
      {
        "id": @sportID,
        "name": sportName,
        "opponents": playerOpponents,
        "rating": rating
        }
      )
  end

  return [player, sportIndex, rating]
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

# let event =
#   {
#     sport: actualSportID,
#     p1InitialRating,
#     opponents,
#     teammates
#   }

def update
  @user = User.find(params[:id])
  if params.has_key?("newEvent")
    @athlete = Sport.find(10)
    @p1ID = @user.id
    # @p2ID = params["newEvent"]["p2ID"]
    @p1Initial = params["newEvent"]["p1InitialRating"]
    p1Name = @user.firstname + " " + @user.lastname
    p1Username = @user.username
    # p2Name = params["newEvent"]["p2Name"]
    # p2Username = params["newEvent"]["p2Username"]
    @sportID = params["newEvent"]["sport"]
    # @p1 = User.find(@p1ID)
    # @p2 = User.find(@p2ID)
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
