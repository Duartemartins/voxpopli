class AddQuestDismissedToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :quest_dismissed, :boolean, default: false, null: false
  end
end
