class CreateSports < ActiveRecord::Migration[6.0]
  def change
    create_table :sports do |t|
      t.string :name
      t.string :alternate_name
      t.json :participants, array: true, default: []
      t.json :events, array: true, default: []

      t.timestamps
    end
  end
end
