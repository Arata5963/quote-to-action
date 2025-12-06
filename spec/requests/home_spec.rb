require 'rails_helper'

RSpec.describe 'Home', type: :request do
  describe 'GET /home' do
    it 'トップページが表示される' do
      get home_path
      expect(response).to have_http_status(:success)
    end

    it 'タイトルが含まれる' do
      get home_path
      expect(response.body).to include('mitadake?')
    end
  end
end
