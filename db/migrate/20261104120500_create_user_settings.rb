class CreateUserSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :user_settings do |t|
      t.references :user, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.decimal :monthly_budget, precision: 12, scale: 2
      t.string :budget_currency, null: false, default: "ARS"

      t.timestamps
    end
  end
end
