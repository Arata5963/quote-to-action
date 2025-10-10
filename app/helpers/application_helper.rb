# app/helpers/application_helper.rb
module ApplicationHelper
  # カテゴリのアイコンを返す
  def category_icon(category_key)
    icons = {
      'text' => '📝',
      'video' => '🎥',
      'audio' => '🎧',
      'conversation' => '💬',
      'experience' => '✨',
      'observation' => '👀',
      'other' => '📁'
    }
    icons[category_key.to_s] || '📁'
  end
  
  # カテゴリ名（絵文字なし）を返す
  def category_name_without_icon(category_key)
    Post.human_attribute_name("category.#{category_key}")
        .gsub(/[📝🎥🎧💬✨👀📁]/, '')
        .strip
  end
end