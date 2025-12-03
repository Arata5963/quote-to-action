class RemoveTriggerContentFromPosts < ActiveRecord::Migration[7.2]
  def change
    remove_column :posts, :trigger_content, :text
  end
end
