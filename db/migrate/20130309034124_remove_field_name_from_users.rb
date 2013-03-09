class RemoveFieldNameFromUsers < ActiveRecord::Migration
  def up
    remove_column :users, :friends
  end

  def down
    add_column :users, :friends, :text
  end
end
