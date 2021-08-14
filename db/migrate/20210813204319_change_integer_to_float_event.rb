class ChangeIntegerToFloatEvent < ActiveRecord::Migration[6.0]
  def change
    remove_column :events, :team1InitialRating, :integer
    add_column :events, :team1InitialRating, :float
    remove_column :events, :team2InitialRating, :integer
    add_column :events, :team2InitialRating, :float
  end
end
