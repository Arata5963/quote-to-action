require 'rails_helper'

RSpec.describe AchievementsHelper, type: :helper do
  describe '#generate_monthly_calendar' do
    let(:mock_post) { instance_double(Post, youtube_thumbnail_url: 'https://example.com/thumb.jpg') }
    let(:achievement_data) do
      {
        Date.new(2024, 12, 11) => { count: 3, first_post: mock_post },
        Date.new(2024, 12, 5) => { count: 1, first_post: mock_post }
      }
    end

    context '2024年12月（1日が日曜）' do
      let(:result) { helper.generate_monthly_calendar(achievement_data, 2024, 12) }

      it '31日分 + 月末の空白4つ = 35セル' do
        expect(result.size).to eq(35)
      end

      it '月初に空白セルがない' do
        expect(result.first[:type]).to eq(:day)
        expect(result.first[:day]).to eq(1)
      end

      it '月末に空白セルが4つある' do
        blank_cells = result.select { |c| c[:type] == :blank }
        expect(blank_cells.size).to eq(4)
      end

      it '達成がある日はhas_achievementがtrue' do
        day_11 = result.find { |c| c[:type] == :day && c[:day] == 11 }
        expect(day_11[:has_achievement]).to be true
      end

      it '達成がない日はhas_achievementがfalse' do
        day_1 = result.find { |c| c[:type] == :day && c[:day] == 1 }
        expect(day_1[:has_achievement]).to be false
      end

      it '達成がある日はサムネイルURLを含む' do
        day_11 = result.find { |c| c[:type] == :day && c[:day] == 11 }
        expect(day_11[:thumbnail_url]).to eq('https://example.com/thumb.jpg')
        expect(day_11[:achievement_count]).to eq(3)
      end

      it '達成がない日はサムネイルURLがnil' do
        day_1 = result.find { |c| c[:type] == :day && c[:day] == 1 }
        expect(day_1[:thumbnail_url]).to be_nil
        expect(day_1[:achievement_count]).to eq(0)
      end
    end

    context '2024年11月（1日が金曜）' do
      let(:result) { helper.generate_monthly_calendar({}, 2024, 11) }

      it '月初に空白セルが5つある' do
        first_five = result.take(5)
        expect(first_five.all? { |c| c[:type] == :blank }).to be true
      end

      it '空白5 + 30日 = 35セル（7の倍数なので末尾空白なし）' do
        expect(result.size).to eq(35)
      end
    end
  end

  describe '#weekday_headers' do
    it '日曜始まりの曜日配列を返す' do
      result = helper.weekday_headers

      expect(result).to eq(%w[日 月 火 水 木 金 土])
    end
  end
end
