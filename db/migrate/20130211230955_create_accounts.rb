class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.integer :uuid
      t.string :screen_name
      t.string :name
      t.string :profile_image_url
      t.string :gender
      t.timestamps
    end
  end
end
