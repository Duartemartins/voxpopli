class CreateWebhooks < ActiveRecord::Migration[8.0]
  def change
    create_table :webhooks, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.string :url, null: false
      t.text :secret
      t.text :events, default: '[]'
      t.boolean :active, default: true
      t.datetime :last_triggered_at
      t.integer :last_status
      t.timestamps
    end
  end
end
