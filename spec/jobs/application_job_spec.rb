# spec/jobs/application_job_spec.rb
require 'rails_helper'

RSpec.describe ApplicationJob, type: :job do
  describe '基本設定' do
    it 'ApplicationJobを継承したジョブが作成できる' do
      test_job = Class.new(ApplicationJob) do
        def perform(value)
          value * 2
        end
      end

      result = test_job.new.perform(5)
      expect(result).to eq(10)
    end

    it 'perform_laterでジョブをキューに追加できる' do
      test_job = Class.new(ApplicationJob) do
        def perform(*_args); end
      end

      expect {
        test_job.perform_later('test_argument')
      }.to have_enqueued_job(test_job).with('test_argument')
    end
  end

  describe '継承関係' do
    it 'ActiveJob::Baseを継承している' do
      expect(ApplicationJob.superclass).to eq(ActiveJob::Base)
    end
  end
end