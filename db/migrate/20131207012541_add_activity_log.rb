class AddActivityLog < ActiveRecord::Migration
  def change
    create_table :activity_logs do |t|
      t.string :action
      t.string :data
      t.integer :user_id
      t.timestamps
    end
  end
end
