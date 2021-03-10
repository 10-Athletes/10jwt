class AddSportsAndEventsToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :events, :json, array:true, default:[]
    add_column :users, :sports, :json, array:true, default:[]
  end
end
