class AddTreatmentToUsers < ActiveRecord::Migration
  def change
    add_column :users, :treatment, :string, :default => "new"
  end
end
