class AddRelatedUrlToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :related_url, :string
  end
end
