class CreateFriendsrecords < ActiveRecord::Migration
  def change
    create_table :friendsrecords do |t|
      t.references :user
      t.text :friends
      t.timestamps
    end
  end
end
