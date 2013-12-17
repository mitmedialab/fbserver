class ChangeFriendsrecordFriendsToMediumText < ActiveRecord::Migration
  def change
    change_column :friendsrecords, :friends, :mediumtext
  end
end
