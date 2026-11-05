class RemoveRedundantUserIndexFromMovements < ActiveRecord::Migration[7.1]
  # (user_id, date) already serves every lookup by user_id alone, since user_id is its leading column.
  def change
    remove_index :movements, :user_id, name: "index_movements_on_user_id"
  end
end
