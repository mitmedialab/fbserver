class ChangeUiDtoBigIntInUsers < ActiveRecord::Migration
  def up
    change_column :users, :uid, :integer, :limit => 8
  end

  def down
    change_column :users, :uid, :string
  end
end
