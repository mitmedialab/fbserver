class AddUserIdIndexToFollowbiasRecords < ActiveRecord::Migration
  def change
    add_index :followbias_records, :user_id
  end
end
