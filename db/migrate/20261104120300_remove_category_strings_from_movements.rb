class RemoveCategoryStringsFromMovements < ActiveRecord::Migration[7.1]
  def change
    remove_index :movements, [ :user_id, :category ]
    remove_column :movements, :category, :string
    remove_column :movements, :subcategory, :string
  end
end
