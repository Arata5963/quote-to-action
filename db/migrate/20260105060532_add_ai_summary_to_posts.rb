class AddAiSummaryToPosts < ActiveRecord::Migration[7.2]
  def change
    add_column :posts, :ai_summary, :text
  end
end
