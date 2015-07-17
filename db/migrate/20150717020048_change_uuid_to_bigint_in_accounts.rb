class ChangeUuidToBigintInAccounts < ActiveRecord::Migration
  def up
    change_column :accounts, :uuid, :integer, :limit => 8
  end

  def down
    change_column :my_table, :my_column, :integer
  end
end
