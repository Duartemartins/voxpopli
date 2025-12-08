class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.references :theme, type: :uuid, foreign_key: true, null: true
      t.references :parent, type: :uuid, foreign_key: { to_table: :posts }, null: true
      t.references :repost_of, type: :uuid, foreign_key: { to_table: :posts }, null: true
      
      t.text :content, null: false
      t.integer :votes_count, default: 0
      t.integer :score, default: 0
      t.integer :replies_count, default: 0
      t.integer :reposts_count, default: 0
      
      t.timestamps
    end
    
    add_index :posts, [:user_id, :created_at]
    add_index :posts, :created_at
    add_index :posts, [:score, :created_at]
    add_index :posts, [:theme_id, :created_at]
  end
end
