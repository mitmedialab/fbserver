class AddTwitterJsonToFriendsRecords < ActiveRecord::Migration
  def change
    add_column :friendsrecords, :twitter_json, :text
  end
end
