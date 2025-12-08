class CreateApiKeys < ActiveRecord::Migration[8.0]
  def change
    create_table :api_keys, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.string :name, null: false
      t.string :key_digest, null: false
      t.string :key_prefix, null: false
      t.integer :requests_count, default: 0
      t.integer :rate_limit, default: 1000
      t.datetime :last_used_at
      t.datetime :expires_at
      t.timestamps
    end

    add_index :api_keys, :key_prefix, unique: true
  end
end
