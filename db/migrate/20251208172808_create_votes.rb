class CreateVotes < ActiveRecord::Migration[8.0]
  def change
    create_table :votes, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.references :post, type: :uuid, null: false, foreign_key: true
      t.integer :value, null: false, default: 1
      t.timestamps
    end
    
    add_index :votes, [:user_id, :post_id], unique: true
  end
end
