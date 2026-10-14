class CreateMovements < ActiveRecord::Migration[7.1]
  def change
    create_table :movements do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :kind, null: false
      t.date :date, null: false
      t.string :description, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :currency, null: false, default: "ARS"
      t.string :category
      t.string :subcategory
      t.string :payment_method
      t.string :credit_card
      t.string :beneficiary
      t.text :notes
      t.boolean :shared, null: false, default: false

      t.timestamps
    end
    add_index :movements, [ :user_id, :date ]
    add_index :movements, [ :user_id, :category ]
  end
end
