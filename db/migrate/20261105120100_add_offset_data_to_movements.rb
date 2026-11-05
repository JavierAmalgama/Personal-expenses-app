class AddOffsetDataToMovements < ActiveRecord::Migration[7.1]
  def change
    add_column :movements, :offset_data, :jsonb
    # jsonb_path_ops only supports @>, but it's smaller and faster than the default opclass for that operator.
    add_index :movements, :offset_data, using: :gin, opclass: :jsonb_path_ops
  end
end
