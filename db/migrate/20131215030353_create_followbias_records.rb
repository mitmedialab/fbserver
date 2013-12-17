class CreateFollowbiasRecords < ActiveRecord::Migration
  def change
    create_table :followbias_records do |t|
      t.integer :user_id
      t.integer :friendsrecord_id
      t.integer :male
      t.integer :female
      t.integer :unknown
      t.integer :total_following
      t.timestamps
    end
  end
end
