class RemoveContentFromPosts < ActiveRecord::Migration[8.0]
  def change
    # First copy content to body for existing posts
    reversible do |dir|
      dir.up do
        execute "UPDATE posts SET body = content WHERE body IS NULL OR body = ''"
      end
    end
    
    # Remove content column
    remove_column :posts, :content, :text
    
    # Make body not null
    change_column_null :posts, :body, false
  end
end
