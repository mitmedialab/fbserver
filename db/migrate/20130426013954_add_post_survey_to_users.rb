class AddPostSurveyToUsers < ActiveRecord::Migration
  def change
    add_column :users, :post_survey, :text
  end
end
