class AddSuggestionsToUsersAndAccounts < ActiveRecord::Migration
  def change
    create_table :account_suggestions do |t|
      t.references :account
      t.text :suggesters #JSON of users
      t.timestamps
    end
    add_column :users, :suggested_accounts, :text, :default => nil
  end
end
