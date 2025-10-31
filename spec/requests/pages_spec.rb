require 'rails_helper'

RSpec.describe 'Pages', type: :request do
  describe 'GET /terms' do
    it '利用規約ページが表示される' do
      get terms_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /privacy' do
    it 'プライバシーポリシーページが表示される' do
      get privacy_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /usage' do
    it '使い方ページが表示される' do
      get usage_path
      expect(response).to have_http_status(:success)
    end
  end
end
