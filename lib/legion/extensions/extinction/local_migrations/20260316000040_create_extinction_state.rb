# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:extinction_state) do
      primary_key :id
      Integer :current_level, null: false, default: 0
      TrueClass :active, null: false, default: false
      String :history, text: true
      DateTime :updated_at
    end
  end
end
