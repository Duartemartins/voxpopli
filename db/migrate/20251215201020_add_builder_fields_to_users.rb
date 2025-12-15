class AddBuilderFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :tagline, :string, limit: 140
    add_column :users, :github_username, :string
    add_column :users, :looking_for, :string
    add_column :users, :skills, :text, default: "[]"
    add_column :users, :launched_products, :text, default: "[]"
    
    add_index :users, :github_username, unique: true, where: "github_username IS NOT NULL"
  end
end
