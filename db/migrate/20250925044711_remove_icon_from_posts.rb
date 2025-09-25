class RemoveIconFromPosts < ActiveRecord::Migration[7.2]
  def change
    remove_column :posts, :icon, :string
  end
end
