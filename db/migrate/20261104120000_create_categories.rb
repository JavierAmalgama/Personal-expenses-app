class CreateCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :categories do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :parent, foreign_key: { to_table: :categories, on_delete: :cascade }
      t.string :name, null: false
      t.string :kind, null: false

      t.timestamps
    end
    add_index :categories, [ :user_id, :parent_id, :name ], unique: true, nulls_not_distinct: true
  end
end
