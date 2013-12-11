class AddTwitterFailureToUsers < ActiveRecord::Migration
  def change
    add_column :users, :failed, :boolean, :default=>false
  end
end
