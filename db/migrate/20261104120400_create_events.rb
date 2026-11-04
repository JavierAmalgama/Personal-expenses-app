class CreateEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :events do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false

      t.timestamps
    end
    add_reference :movements, :event, foreign_key: { on_delete: :nullify }
  end
end
