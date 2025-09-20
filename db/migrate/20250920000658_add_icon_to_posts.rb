class AddIconToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :icon, :string
  end
end
