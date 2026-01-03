class AddBlogFieldsToPostEntries < ActiveRecord::Migration[7.2]
  def change
    add_column :post_entries, :title, :string
    add_column :post_entries, :published_at, :datetime
  end
end
