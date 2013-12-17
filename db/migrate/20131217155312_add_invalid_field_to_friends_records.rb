class AddInvalidFieldToFriendsRecords < ActiveRecord::Migration
  def change
    add_column :friendsrecords, :incomplete, :boolean, :default=>false
  end
end
