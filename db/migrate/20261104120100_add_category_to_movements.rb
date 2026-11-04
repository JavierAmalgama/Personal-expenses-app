class AddCategoryToMovements < ActiveRecord::Migration[7.1]
  def change
    add_reference :movements, :category, foreign_key: { on_delete: :nullify }
  end
end
