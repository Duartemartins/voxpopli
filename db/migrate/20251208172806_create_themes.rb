class CreateThemes < ActiveRecord::Migration[8.0]
  def change
    create_table :themes, id: :string do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :color, default: '#003399'
      t.integer :posts_count, default: 0
      t.timestamps
    end

    add_index :themes, :slug, unique: true
  end
end
