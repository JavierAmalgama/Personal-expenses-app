class ConvertEnumColumnsToPostgresEnums < ActiveRecord::Migration[7.1]
  ENUM_COLUMNS = [
    [ :movements, :kind, :movement_kind ],
    [ :categories, :kind, :movement_kind ],
    [ :movements, :currency, :currency ],
    [ :user_settings, :budget_currency, :currency ],
    [ :movements, :payment_method, :payment_method ],
    [ :movements, :credit_card, :credit_card_brand ]
  ].freeze

  CURRENCY_DEFAULTS = [ [ :movements, :currency ], [ :user_settings, :budget_currency ] ].freeze

  def up
    create_enum :movement_kind, %w[income expense]
    create_enum :currency, %w[ARS USD]
    create_enum :payment_method, %w[cash debit_card credit_card transfer other]
    create_enum :credit_card_brand, %w[visa amex mercado_pago other]

    # A string default can't be cast to the enum automatically, so it's dropped and restored around the type change.
    CURRENCY_DEFAULTS.each { |table, column| change_column_default table, column, nil }
    ENUM_COLUMNS.each do |table, column, type|
      execute "ALTER TABLE #{table} ALTER COLUMN #{column} TYPE #{type} USING #{column}::#{type}"
    end
    CURRENCY_DEFAULTS.each { |table, column| change_column_default table, column, "ARS" }
  end

  def down
    CURRENCY_DEFAULTS.each { |table, column| change_column_default table, column, nil }
    ENUM_COLUMNS.each do |table, column, _type|
      execute "ALTER TABLE #{table} ALTER COLUMN #{column} TYPE varchar USING #{column}::text"
    end
    CURRENCY_DEFAULTS.each { |table, column| change_column_default table, column, "ARS" }

    drop_enum :credit_card_brand
    drop_enum :payment_method
    drop_enum :currency
    drop_enum :movement_kind
  end
end
