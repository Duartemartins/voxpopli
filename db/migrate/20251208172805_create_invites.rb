class CreateInvites < ActiveRecord::Migration[8.0]
  def change
    create_table :invites, id: :string do |t|
      t.references :inviter, type: :string, foreign_key: { to_table: :users }, null: true
      t.references :invitee, type: :string, foreign_key: { to_table: :users }, null: true
      t.string :code, null: false
      t.string :email
      t.datetime :used_at
      t.datetime :expires_at
      t.timestamps
    end

    add_index :invites, :code, unique: true
  end
end
