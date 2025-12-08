class CreateFollows < ActiveRecord::Migration[8.0]
  def change
    create_table :follows, id: :string do |t|
      t.references :follower, type: :string, null: false, foreign_key: { to_table: :users }
      t.references :followed, type: :string, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :follows, [ :follower_id, :followed_id ], unique: true
  end
end
