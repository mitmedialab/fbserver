class AddIndexToFriendsRecords < ActiveRecord::Migration
  def change
    add_index :friendsrecords, :user_id
  end
end
