class CreateBookmarks < ActiveRecord::Migration[8.0]
  def change
    create_table :bookmarks, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.references :post, type: :uuid, null: false, foreign_key: true
      t.timestamps
    end

    add_index :bookmarks, [ :user_id, :post_id ], unique: true
  end
end
