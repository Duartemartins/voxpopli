class AddPaymentFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :payment_method, :string
    add_column :users, :paid_at, :datetime
  end
end
