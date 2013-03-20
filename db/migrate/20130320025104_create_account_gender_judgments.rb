class CreateAccountGenderJudgments < ActiveRecord::Migration
  def change
    create_table :account_gender_judgments do |t|
      t.integer :account_id
      t.integer :user_id
      t.string  :gender
      t.timestamps
    end
  end
end
