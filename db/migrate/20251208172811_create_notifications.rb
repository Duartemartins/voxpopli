class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications, id: :string do |t|
      t.references :user, type: :string, null: false, foreign_key: true
      t.references :actor, type: :string, null: false, foreign_key: { to_table: :users }
      t.string :notifiable_type
      t.string :notifiable_id
      t.string :action, null: false
      t.boolean :read, default: false
      t.timestamps
    end

    add_index :notifications, [ :notifiable_type, :notifiable_id ]
    add_index :notifications, [ :user_id, :read, :created_at ]
  end
end
