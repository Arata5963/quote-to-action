class CreateReminders < ActiveRecord::Migration[7.2]
  def change
    create_table :reminders do |t|
      t.references :user, null: false, foreign_key: true
      t.boolean :enabled
      t.time :time

      t.timestamps
    end
  end
end
