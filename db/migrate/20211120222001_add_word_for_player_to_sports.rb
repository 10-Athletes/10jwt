class AddWordForPlayerToSports < ActiveRecord::Migration[6.0]
  def change
    add_column :sports, :wordForPlayer, :string
  end
end
