class CreateEvents < ActiveRecord::Migration[6.0]
  def change
    create_table :events do |t|
      t.integer :sport
      t.integer :p1ID
      t.integer :p1InitialRating
      t.integer :p2ID
      t.integer :p2InitialRating
      t.integer :winner
      t.timestamps
    end
  end
end
