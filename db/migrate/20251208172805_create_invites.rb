class CreateInvites < ActiveRecord::Migration[8.0]
  def change
    create_table :invites, id: :uuid do |t|
      t.references :inviter, type: :uuid, foreign_key: { to_table: :users }, null: true
      t.references :invitee, type: :uuid, foreign_key: { to_table: :users }, null: true
      t.string :code, null: false
      t.string :email
      t.datetime :used_at
      t.datetime :expires_at
      t.timestamps
    end
    
    add_index :invites, :code, unique: true
  end
end
