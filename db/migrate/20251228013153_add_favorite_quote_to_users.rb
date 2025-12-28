class AddFavoriteQuoteToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :favorite_quote, :string, limit: 50
    add_column :users, :favorite_quote_url, :string
  end
end
