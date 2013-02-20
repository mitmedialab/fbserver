class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :provider
      t.string :uid
      t.string :name
      t.string :friends
      t.string :screen_name
      t.string :twitter_token
      t.string :twitter_secret
      t.timestamps
    end
  end
end
