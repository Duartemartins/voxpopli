class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments, id: :string do |t|
      t.references :user, null: false, foreign_key: true, type: :string
      t.integer :amount_cents, null: false, default: 500
      t.string :currency, null: false, default: "usd"
      t.string :stripe_payment_id
      t.string :stripe_session_id
      t.string :status, null: false, default: "pending"
      t.string :payment_method

      t.timestamps
    end

    add_index :payments, :stripe_session_id, unique: true, where: "stripe_session_id IS NOT NULL"
    add_index :payments, :stripe_payment_id, unique: true, where: "stripe_payment_id IS NOT NULL"
    add_index :payments, :status
  end
end
