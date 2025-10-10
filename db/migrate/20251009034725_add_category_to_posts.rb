class AddCategoryToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :category, :integer, default: 6, null: false
    add_index :posts, :category
  end
end
