class RenameLikesToCheers < ActiveRecord::Migration[7.2]
  def change
    rename_table :likes, :cheers
  end
end
