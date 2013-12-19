class AddProfileImageUpdatedFieldToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :profile_image_updated_at, :datetime
  end
end
