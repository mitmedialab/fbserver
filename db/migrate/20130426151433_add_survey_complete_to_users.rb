class AddSurveyCompleteToUsers < ActiveRecord::Migration
  def change
    add_column :users, :survey_complete, :boolean, :default=>0
  end
end
