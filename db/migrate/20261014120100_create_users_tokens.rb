class CreateUsersTokens < ActiveRecord::Migration[7.1]
  def change
    create_table :users_tokens do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :token, null: false
      t.datetime :valid_until

      t.timestamps
    end
    add_index :users_tokens, :token, unique: true
  end
end
