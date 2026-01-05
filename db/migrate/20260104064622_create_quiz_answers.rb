class CreateQuizAnswers < ActiveRecord::Migration[7.2]
  def change
    create_table :quiz_answers do |t|
      t.references :user, null: false, foreign_key: true
      t.references :quiz, null: false, foreign_key: true
      t.integer :score
      t.integer :total_questions

      t.timestamps
    end
  end
end
