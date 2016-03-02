class CreateOrganizations < ActiveRecord::Migration
  def change
    create_table :organizations do |t|
      t.string :name
			t.string :state
			t.string :city
			t.string :twitter_lists
      t.timestamps
    end
    create_table :organizations_users do |t|
      t.belongs_to :organization, index: true
      t.belongs_to :user, index: true
      t.timestamps
    end
  end
end
