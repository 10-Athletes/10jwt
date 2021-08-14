class ChangeIndividualEventToTeam < ActiveRecord::Migration[6.0]
  def change
    remove_column :events, :p1ID, :integer
    remove_column :events, :p2ID, :integer
    remove_column :events, :p1InitialRating, :integer
    remove_column :events, :p2InitialRating, :integer
    add_column :events, :team1, :json, array:true, default:[]
    add_column :events, :team2, :json, array:true, default:[]
    add_column :events, :team1InitialRating, :integer
    add_column :events, :team2InitialRating, :integer
  end
end
