class CreateSegments < ActiveRecord::Migration
  def change
    create_table :segments do |t|
      t.string :name
      t.string :subsegment
      t.timestamps
    end
    create_table :segments_users do |t|
      t.belongs_to :user, index: true
      t.belongs_to :segment, index: true
      t.timestamps
    end
  end
end
