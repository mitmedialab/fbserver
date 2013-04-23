class AddLastNextApiAccessToUser < ActiveRecord::Migration
  def change
    add_column :users, :next_scheduled_api_poll, :datetime
    add_column :users, :last_api_poll, :datetime
  end
end
