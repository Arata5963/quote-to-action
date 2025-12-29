class ChangeDeadlineNullOnPosts < ActiveRecord::Migration[7.2]
  def change
    change_column_null :posts, :deadline, true
  end
end
