# app/jobs/generate_summary_job.rb
# 投稿作成時にAI要約を自動生成するバックグラウンドジョブ
class GenerateSummaryJob < ApplicationJob
  queue_as :default

  def perform(post_id)
    post = Post.find_by(id: post_id)
    return unless post
    return if post.ai_summary.present? # 既に要約がある場合はスキップ

    Rails.logger.info("Generating AI summary for post ##{post_id}")

    result = GeminiService.summarize_video(post)

    if result[:success]
      post.update(ai_summary: result[:summary])
      Rails.logger.info("AI summary generated successfully for post ##{post_id}")
    else
      Rails.logger.warn("Failed to generate AI summary for post ##{post_id}: #{result[:error]}")
    end
  rescue StandardError => e
    Rails.logger.error("Error in GenerateSummaryJob for post ##{post_id}: #{e.message}")
  end
end
