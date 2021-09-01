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
    team1 = [@user]
    team1 += params["newEvent"]["teammates"]
    team2 = params["newEvent"]["opponents"]
    @team1 = []
    @team2 = []
    team1Rating = 0
    team2Rating = 0
    team1Opponents = []
    team1Ratings = []
    team2Opponents = []
    team2Ratings = []
    numRated = 0
    sportIndeces = []
    athleteIndeces = []
    team1.each_with_index do |player, idx|
      currentPlayer = User.find(player["id"])
      updatedPlayer = getInitialRatingData(1, currentPlayer)
      # puts "updatedplayersports#{updatedPlayer[0]["sports"]}"
      @team1.push(updatedPlayer[0])
      # puts "team1p1sports: #{@team1[0]["sports"]}"
      if idx == 0 && updatedPlayer[2] == 0
        p1InitialRating = params["newEvent"]["p1InitialRating"]
        team1Ratings.push(p1InitialRating)
        team1Rating += p1InitialRating
        numRated += 1
      else
        team1Ratings.push(updatedPlayer[2])
        team1Rating += updatedPlayer[2]
      end
      if updatedPlayer[2] > 0
        numRated += 1
      end
      sportIndeces.push(updatedPlayer[1])
      athleteIndeces.push(updatedPlayer[3])
    end
    team1Rating = team1Rating / numRated
    team1Ratings.each_with_index do |playerRating, idx|
      if playerRating == 0
        team1Ratings[idx] = team1Rating
        playerRating = team1Rating
        @team1[idx]["sports"][sportIndeces[idx]]["rating"] = playerRating
      end
    end
    numRated = 0
    team2.each do |player|
      currentPlayer = User.find(player["id"])
      updatedPlayer = getInitialRatingData(2, currentPlayer)
      @team2.push(updatedPlayer[0])
      team2Rating += updatedPlayer[2]
      team2Ratings.push(updatedPlayer[2])
      if updatedPlayer[2] > 0
        numRated += 1
      end
      puts "updatedPlayer"
      puts updatedPlayer.as_json
      sportIndeces.push(updatedPlayer[1])
      athleteIndeces.push(updatedPlayer[3])
    end
    if numRated == 0
      team2Rating = team1Rating
    else
      team2Rating = team2Rating / numRated
    end
    team2Ratings.each_with_index do |playerRating, idx|
      if playerRating == 0
        playerRating = team2Rating
        team2Ratings[idx] = team2Rating
        @team2[idx]["sports"][sportIndeces[idx + @team1.length]]["rating"] = playerRating
      end
    end

  @winner = params["newEvent"]["winner"]
  @event = {}
    @event["sport"] = @sportID
    @event["team1"] = []
    @event["team2"] = []
    @event["winner"] = @winner

  @team1.each_with_index do |player, idx|
    @event["team1"][idx] = {}
    @event["team1"][idx]["id"] = player["id"]
    @event["team1"][idx]["initialRating"] = team1Ratings[idx]
  end
  @team2.each_with_index do |player, idx|
    @event["team2"][idx] = {}
    @event["team2"][idx]["id"] = player["id"]
    @event["team2"][idx]["initialRating"] = team2Ratings[idx]
  end

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
  if @winner == "1" || @winner == 1
    won = true
  else
    won = false
  end

  @team1.each_with_index do |player, index|
    # if player["sports"].length == 0
    #   numberOfOpponents = 0
    # else
    player["sports"][sportIndeces[index]]["opponents"] ||= player["sports"][sportIndeces[index]][:opponents]
    numberOfOpponents = player["sports"][sportIndeces[index]]["opponents"].length
    # end
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
    finalRating = calculate(player, rating, change, won, modifierVariable)
    puts "rating before"
    puts rating
    puts "rating after"
    puts finalRating
    puts "sportIndeces"
    puts sportIndeces
    puts "athleteIndeces"
    puts athleteIndeces
    puts "index"
    puts index
    puts "player sports"
    puts player["sports"]
    player["sports"][sportIndeces[index]]["rating"] = finalRating
    puts "updatedfinalrating"
    puts player["sports"]
    @event["team1"][index]["ratingChange"] = finalRating - @event["team1"][index]["initialRating"]
    team1Ratings[index] = finalRating
  end
  if @winner != "1" && @winner != 1
    won = true
  else
    won = false
  end
  #TODO DRY out this code
  @team2.each_with_index do |player, index|
    numberOfGames = 0
    # if player["sports"].length == 0
    #   numberOfOpponents = 0
    # else
    # a = index + @team1.length
    player["sports"][sportIndeces[index + @team1.length]]["opponents"] ||= player["sports"][sportIndeces[index + @team1.length]][:opponents]
    numberOfOpponents = player["sports"][sportIndeces[index + @team1.length]]["opponents"].length
    # end
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
    if team2Ratings[index] == 0
      rating = team2Rating
    else
      rating = team2Ratings[index]
    end
    finalRating = calculate(player, rating, change, won, modifierVariable)
    player["sports"][sportIndeces[index + @team1.length]]["rating"] = finalRating
    @event["team2"][index]["ratingChange"] = finalRating - @event["team2"][index]["initialRating"]
    team2Ratings[index] = finalRating
  end
  @event["team1InitialRating"] = team1Rating
  @event["team2InitialRating"] = team2Rating
  return [sportIndeces, team1Ratings + team2Ratings, athleteIndeces]
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
  puts "didyourteamwin"
  puts yourTeamWon
  if yourTeamWon
    puts "yourteamwon"
    puts player.as_json
    puts "change"
    puts change
    puts "modifier"
    puts modifier
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
    puts "yourteamlost"
    puts player.as_json
    puts "change"
    puts change
    puts "modifier"
    puts modifier
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
    currentGameOpponents = [@user] + params["newEvent"]["teammates"]
  end
  rating = 0
  sportFound = false
  athleteFound = false
  sportIndex = -1
  athleteIndex = -1
  player["sports"].each_with_index do |sport, idx|
    if sport["id"] == "10" || sport["id"] == 10
      athleteFound = true
      athleteIndex = idx
    end
    if sport["id"] == "#{@sportID}" || sport["id"] == @sportID
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
    playerOpponents = []
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
  return [player, sportIndex, rating, athleteIndex]
end

def updateAthlete(index, team, player, sportIndex)
  if team == 1
    rating = player["sports"][sportIndex]["rating"]
    opponents = player["sports"][sportIndex]["opponents"]
    # data = @p1Data
  elsif team == 2
    # puts "player!"
    # puts player.as_json["sports"][2]
    # puts sportIndex
    # puts  @team1.length
    rating = player["sports"][sportIndex]["rating"]
    opponents = player["sports"][sportIndex]["opponents"]
  end
  sportIncluded = false
  official = false
  # Please make this more efficient.
  # currently loops through here to figure out
  # if any sport is official prior to looping through
  # the same content later
  @athlete["participants"][index]["sports"].each do |sport|
    sport["numGames"] ||= 0
    if sport["id"] == @sportID
      sport["rating"] = rating
      sport["opponents"] = opponents
      sportIncluded = true
      sport["numGames"] += 1
      if opponents.length >= 5
        numGames = sport["numGames"]
        official = true if numGames >= 5
      end
    end
  end
  unless sportIncluded
    sportsArr = []
    insert_at = @athlete["participants"][index]["sports"].bsearch_index {|sport| sport["rating"] < rating}
     unless insert_at
       insert_at = @athlete["participants"][index]["sports"].length
     end
    @athlete["participants"][index]["sports"].each_with_index do |sport, i|
      if i == insert_at
        currentSpot = {}
        currentSpot["id"] = @sportID
        currentSpot["rating"] = rating
        currentSpot["opponents"] = opponents
        currentSpot["numGames"] = 1
        sportsArr[sportsArr.length] = currentSpot
        # sportsArr.push({id: @sportID, rating: rating, opponents: opponents, numGames: 1})
      end
      sportsArr.push(sport)
      # For timing purposes I need to have this line here. This is the case where the sport goes into the
      # last position in the array as nothing is lower rating than it.
      if i == insert_at - 1 && i == @athlete["participants"][index]["sports"].length - 1
        currentSpot = {}
        currentSpot["id"] = @sportID
        currentSpot["rating"] = rating
        currentSpot["opponents"] = opponents
        currentSpot["numGames"] = 1
        sportsArr[sportsArr.length] = currentSpot
        # [sport1, sport2]
        # sportsArr.push({id: @sportID, rating: rating, opponents: opponents, numGames: 1})
      end
    end

    @athlete["participants"][index]["sports"] = sportsArr
    # .insert(insert_at, {id: @sportID, rating: data[1], opponents: [opponentID]})
  end
  currentSportRating = rating
  error = ""
  rating = 0
  count = 0
  maxRating = 0
  if official
    officialSports = []
    @athlete["participants"][index]["official"] = true
    @athlete["participants"][index]["sports"].each_with_index do |sport, i|
      thisRating = currentSportRating
      thisOpponents = opponents
      unless i == insert_at
        thisRating = sport["rating"]
        thisOpponents = sport["opponents"]
      end
      #UPDATE FORMULA:
      #If 1 sport: 100%
      #If 2 sports: 65% of sport1 + 45% of sport2
      #If 3 sports: 55% of sport1 + 35% of sport2 + 25% of sport3
      #If 4 sports: 50% of sport1 + 30% of sport2 + 25% of sport3 + 15% of sport4
      #If 5 sports: 50% of sport1 + 30% of sport2 + 20% of sport3 + 15% of sport4 + 10% of sport5
      puts "thisopplen: #{thisOpponents.length}"
      puts "athleteparticipantsindex: #{@athlete["participants"][index]}"
      if thisOpponents.length >= 5 && @athlete["participants"][index]["sports"][i]["numGames"] >= 5
        officialSports.push(sport)
      end
        # thisRating = sport["rating"]
        # if count == 0 ### [10,9,8,7,6]
        #   maxRating = thisRating #10
        #   rating = thisRating * 0.5 #rating = 5
        # elsif count == 1
        #   rating = rating + thisRating * 0.35 # rating = 8.15
        #   maxRating = rating if rating > maxRating
        # elsif count == 2
        #   rating = rating + thisRating * 0.2 #rating = 9.75
        #   maxRating = rating if rating > maxRating
        # elsif count == 3
        #   rating = rating + thisRating * 0.1 # rating = 10.45
        #   maxRating = rating if rating > maxRating
        # elsif count == 4
        #   rating = rating + thisRating * 0.05 # rating = 10.75
        #   maxRating = rating if rating > maxRating
        # end
        # count += 1
      # end
    end
    maxRating = athleteRatingCalculation(officialSports)
  else
    @athlete["participants"][index]["official"] = false
    maxRating = athleteRatingCalculation(@athlete["participants"][index]["sports"])
  end
  #   @athlete["participants"][index]["sports"].each_with_index do |sport, i|
  #     thisRating = currentSportRating
  #     unless i == insert_at
  #       thisRating = sport["rating"]
  #     end
  #     if i == 0
  #       rating = thisRating
  #       maxRating = rating
  #     elsif i == 1
  #       rating = rating * 0.5 + thisRating * 0.35
  #       maxRating = rating if rating > maxRating
  #     elsif i == 2
  #       rating = rating + thisRating * 0.2
  #       maxRating = rating if rating > maxRating
  #     elsif i == 3
  #       rating = rating + thisRating * 0.1
  #       maxRating = rating if rating > maxRating
  #     elsif i == 4
  #       rating = rating + thisRating * 0.05
  #       maxRating = rating if rating > maxRating
  #     end
  #   end
  # end
  # # rating = @athlete["participants"][index]["sports"]

  @athlete["participants"][index]["rating"] = maxRating
  return [maxRating, official]
end

def athleteRatingCalculation(sports)
  if sports.length >= 1
    maxRating = sports[0]["rating"]
  else
    maxRating = 0
  end
  if sports.length >= 2
    # sports[0]["rating"] ||= sports[0][:rating]
    # sports[1]["rating"] ||= sports[1][:rating]
    rating = sports[0]["rating"] * 0.55 + sports[1]["rating"] * 0.5
    if rating > maxRating + sports[1]["rating"] * 0.01
      maxRating = rating
    else
      maxRating = maxRating + sports[1]["rating"] * 0.01
    end
  end
  #scenarios:
  # 1) avg of sports + 10% top rated = max
  # 2) sport1+1%(sport2) + 1%(sport3) = max
  # 3) avg of sport1/2 + 5% sport1 + 1%(sport3) = max
  if sports.length >= 3
    # sports[2]["rating"] ||= sports[2][:rating]
    rating = sports[0]["rating"] / 3 + sports[0]["rating"] / 10 + sports[1]["rating"] / 3
    rating += sports[2]["rating"] / 3
    if rating > maxRating + sports[2]["rating"] * 0.01
      maxRating = rating  #case 1
    else
      maxRating = maxRating + sports[2]["rating"] * 0.01 # case2 AND case3
    end
  end
  #scenarios:
  # 1) avg of sports + 15% top rated = max
  # 2) sport1+1%(sport2) + 1%(sport3) = max
  # 3) avg of sport1/2 + 5% sport1 + 1%(sport3) = max
  if sports.length >= 4
    # sports[3]["rating"] ||= sports[3][:rating]
    rating = sports[0]["rating"] * 0.4 + sports[1]["rating"] * 0.25
    rating += sports[2]["rating"] * 0.25 + sports[3]["rating"] * 0.25
    if rating > maxRating + sports[3]["rating"] * 0.01
      maxRating = rating
    else
      maxRating = maxRating + sports[3]["rating"] * 0.01
    end
  end
  if sports.length >= 5
    # sports[4]["rating"] ||= sports[4][:rating]
    rating = sports[0]["rating"] * 0.4 + sports[1]["rating"] * 0.2
    rating += sports[2]["rating"] * 0.2 + sports[3]["rating"] * 0.2
    rating += sports[4]["rating"] * 0.2
    if rating > maxRating + sports[4]["rating"] * 0.01
      maxRating = rating
    else
      maxRating = maxRating + sports[4]["rating"] * 0.01
    end
  end
  return maxRating
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
  render json: {status: 200, updated: true}
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
    ratingChangeData = ratingChange()
    sportIndeces = ratingChangeData[0]
    ratings = ratingChangeData[1]
    puts "ratings"
    puts ratings
    # this is the index within the User: Sports array
    # that matches the athlete sport (id=10)
    individualAthleteIndeces = ratingChangeData[2]
    puts "IAI"
    puts individualAthleteIndeces
    playerIDs = []
    # This is the index within the Athlete Sport for the
    # matching user
    athleteIndeces = []
    # The index within the sport being played for the
    # matching user
    indecesWithinSport = []
    @team1.each do |player|
      playerIDs.push(player["id"])
      athleteIndeces.push(-1)
      indecesWithinSport.push(-1)
      player["events"].push(@event)
    end
    @team2.each do |player|
      playerIDs.push(player["id"])
      athleteIndeces.push(-1)
      indecesWithinSport.push(-1)
      player["events"].push(@event)
    end
    Event.create(@event)
    @athlete["participants"].each_with_index do |participant, index|
      playerIDs.each_with_index do |playerID, i|
        if participant["id"] == playerID
          athleteIndeces[i] = index
        end
      end
    end
    newAthleteParticipants = []
    # pushing to array was having timing issues
    # resolved it by just setting to count position in array
    count = 0
    puts "indeces"
    puts athleteIndeces
    @team1.each_with_index do |player, i|
      if athleteIndeces[i] < 0
        name = player["firstname"] + " " + player["lastname"]
        athleteIndeces[i] = @athlete["participants"].length + newAthleteParticipants.length
        count += 1
        newAthleteParticipants[count-1] =
        {
          id: player["id"],
          name: name,
          username: player["username"],
          rating: ratings[i],
          official: false,
          sports:
          [{
            id: @sportID,
            rating: player["sports"][sportIndeces[i]]["rating"],
            opponents: player["sports"][sportIndeces[i]]["opponents"],
            numGames: 1
          }]
        }
        player["sports"].push(
          {
            id: "10",
            name: "Athlete",
            rating: player["sports"][sportIndeces[i]]["rating"],
            official: false
          }
        )
        puts "abouttosaveif"
        puts player.as_json
        player.save!
      else
        currentPlayerAthleteRating = updateAthlete(athleteIndeces[i], 1, player, sportIndeces[i])
        puts "playerbeforeupdateathlete"
        puts player.as_json
        puts
        player["sports"][individualAthleteIndeces[i]]["rating"] = currentPlayerAthleteRating[0]
        player["sports"][individualAthleteIndeces[i]]["official"] = currentPlayerAthleteRating[1]
        puts "abouttosaveelse"
        puts player.as_json
        player.save!
        # player["sports"].each do |sport|
        #   if sport["id"] == "10"
        #     sport["rating"] = currentPlayerAthleteRating
        #     found = false
        #     sport["sports"].each do |athleteSport|
        #       if athleteSport == @sportID
        #         found = true
        #       end
        #       sport["sports"].push(@sportID) unless found
        #     end
        #   end
        # end
      end
    end
    newAthleteTeam2Participants = []
    count2 = 0
    @team2.each_with_index do |player, i|
      if athleteIndeces[i + @team1.length] < 0
        name = player["firstname"] + " " + player["lastname"]
        athleteIndeces[i+@team1.length] = @athlete["participants"].length + newAthleteParticipants.length + newAthleteTeam2Participants.length
        count2 += 1
        newAthleteTeam2Participants[count2-1] =
        ({
          id: player["id"],
          name: name,
          username: player["username"],
          rating: ratings[i+@team1.length],
          official: false,
          sports:
          [{
            id: @sportID,
            rating: player["sports"][sportIndeces[i + @team1.length]]["rating"],
            opponents: player["sports"][sportIndeces[i + @team1.length]]["opponents"],
          }]
        })
        player["sports"].push(
          {
            id: "10",
            name: "Athlete",
            rating: player["sports"][sportIndeces[i + @team1.length]]["rating"],
            official: false
          }
        )
        player.save!
      else
        currentPlayerAthleteRating = updateAthlete(athleteIndeces[i + @team1.length], 2, player, sportIndeces[i+@team1.length])
        player["sports"][individualAthleteIndeces[i + @team1.length]]["rating"] = currentPlayerAthleteRating[0]
        player["sports"][individualAthleteIndeces[i + @team1.length]]["official"] = currentPlayerAthleteRating[1]
        player.save!
      end
    end
    @athlete["participants"] += newAthleteParticipants + newAthleteTeam2Participants
    puts @athlete.as_json
    @athlete.save!
    @sport = Sport.find(@sportID)
    @sport["participants"].each_with_index do |participant, index|
      playerIDs.each_with_index do |player, i|
        if participant["id"] == player
          indecesWithinSport[i] = index
        end
      end
    end
    participantsLength = @sport["participants"].length
    @team1.each_with_index do |player, i|
      puts "team1 included?"
      puts indecesWithinSport[i]
      if indecesWithinSport[i] < 0
        name = player["firstname"] + " " + player["lastname"]
        # indecesWithinSport[i] = @sport["participants"].length
        @sport["participants"][participantsLength] =
        {
          id: player["id"],
          name: name,
          username: player["username"],
          rating: ratings[i],
          opponents: player["sports"][sportIndeces[i]]["opponents"],
          gamesPlayed: 1
        }
        participantsLength += 1
      else
        @sport["participants"][indecesWithinSport[i]]["rating"] = ratings[i]
        @sport["participants"][indecesWithinSport[i]]["opponents"] = player["sports"][sportIndeces[i]]["opponents"]
        @sport["participants"][indecesWithinSport[i]]["gamesPlayed"] ||= 0
        @sport["participants"][indecesWithinSport[i]]["gamesPlayed"] += 1
      end
    end
    @team2.each_with_index do |player, i|
      thisPlayer = player.as_json
      if indecesWithinSport[i + @team1.length] < 0
        name = thisPlayer["firstname"] + " " + thisPlayer["lastname"]
        # indecesWithinSport[i+@team1.length] = @sport["participants"].length
        @sport["participants"][participantsLength] =
        {
          id: thisPlayer["id"],
          name: name,
          username: thisPlayer["username"],
          rating: ratings[i+@team1.length],
          opponents: thisPlayer["sports"][sportIndeces[i+@team1.length]]["opponents"]
        }
        participantsLength += 1
      else
        @sport["participants"][indecesWithinSport[i+@team1.length]]["rating"] = ratings[i+@team1.length]
        @sport["participants"][indecesWithinSport[i+@team1.length]]["opponents"] = thisPlayer["sports"][sportIndeces[i+@team1.length]]["opponents"]
        @sport["participants"][indecesWithinSport[i+@team1.length]]["gamesPlayed"] ||= 0
        @sport["participants"][indecesWithinSport[i+@team1.length]]["gamesPlayed"] += 1
      end
    end
    @sport["events"][@sport["events"].length] = @event
    @sport.save!
    # sports = []
    # sportIncluded = false
    # athleteIncluded = false
    # @p1["sports"].each do |sport|
    #   if @sportID == sport["id"]
    #     sportIncluded = true
    #     sport["rating"] = @p1Data[1]
    #     sport["opponents"] = @p1Data[0]
    #   end
    #   if sport["id"] == 10
    #     athleteIncluded = true
    #     sport["rating"] = @athlete["participants"][p1Index]["rating"]
    #     sport["sports"] = @athlete["participants"][p1Index]["sports"]
    #     sport["official"] = @athlete["participants"][p1Index]["official"]
    #   end
    #   sports.push(sport)
    # end
    # unless sportIncluded
    #   sports.push({
    #     id: @sportID,
    #     name: params["newEvent"]["sportName"],
    #     rating: @p1Data[1],
    #     opponents: @p1Data[0]
    #   })
    # end
    # unless athleteIncluded
    #   sports.push({
    #     id: 10,
    #     name: "Athlete",
    #     rating: @p1Data[1],
    #     official: false,
    #     sports: [{
    #       id: @sportID,
    #       rating: @p1Data[1],
    #       opponents: @p1Data[0]
    #     }]
    #   })
    # end
    # @p1["sports"] = sports
    # @p1["events"].push({
    #   sport: @sportID,
    #   p1ID: @p1ID,
    #   p1InitialRating: @p1Data[2],
    #   p2ID: @p2ID,
    #   p2InitialRating: @p2Data[2],
    #   winner: @winner,
    #   created: Time.now
    #   })
    # @p1.save!
    # sports = []
    # sportIncluded = false
    # athleteIncluded = false
    # @p2["sports"].each do |sport|
    #   if @sportID == sport["id"]
    #     sportIncluded = true
    #     sport["rating"] = @p2Data[1]
    #     sport["opponents"] = @p2Data[0]
    #   end
    #   if sport["id"] == 10
    #     athleteIncluded = true
    #     sport["rating"] = @athlete["participants"][p2Index]["rating"]
    #     sport["sports"] = @athlete["participants"][p2Index]["sports"]
    #     sport["official"] = @athlete["participants"][p2Index]["official"]
    #   end
    #   sports.push(sport)
    # end
    # unless sportIncluded
    #   sports.push({
    #     id: @sportID,
    #     name: params["newEvent"]["sportName"],
    #     rating: @p2Data[1],
    #     opponents: @p2Data[0]
    #   })
    # end
    # unless athleteIncluded
    #   sports.push({
    #     id: 10,
    #     name: "Athlete",
    #     rating: @p2Data[1],
    #     official: false,
    #     sports: [{
    #       id: @sportID,
    #       rating: @p2Data[1],
    #       opponents: @p2Data[0]
    #     }]
    #   })
    # end
    # @p2["sports"] = sports
    # @p2["events"].push({
    #   sport: @sportID,
    #   p1ID: @p1ID,
    #   p1InitialRating: @p1Data[2],
    #   p2ID: @p2ID,
    #   p2InitialRating: @p2Data[2],
    #   winner: @winner,
    #   created: Time.now
    #   })
    # @p2.save!
    # @athlete.save!
    # @sport = Sport.find(@sportID)
    # p1Updated = false
    # p2Updated = false
    # @sport.participants.each do |participant|
    #   if participant["id"] == @p1ID
    #     p1Updated = true
    #     participant["rating"] = @p1Data[1]
    #     participant["opponents"] = @p1Data[0]
    #   elsif participant["id"] == @p2ID
    #     p2Updated = true
    #     participant["rating"] = @p2Data[1]
    #     participant["opponents"] = @p2Data[0]
    #   end
    # end
    # unless p1Updated
    #   @sport["participants"].push({
    #     id: @p1ID,
    #     name: p1Name,
    #     username: p1Username,
    #     rating: @p1Data[1],
    #     opponents: @p1Data[0],
    #     })
    # end
    # unless p2Updated
    #   @sport["participants"].push({
    #     id: @p2ID,
    #     name: p2Name,
    #     username: p2Username,
    #     rating: @p2Data[1],
    #     opponents: @p2Data[0],
    #     })
    # end
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
