# spec/helpers/application_helper_spec.rb
require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#category_icon' do
    it 'text カテゴリのアイコンを返す' do
      expect(helper.category_icon('text')).to eq('📝')
    end

    it 'video カテゴリのアイコンを返す' do
      expect(helper.category_icon('video')).to eq('🎥')
    end

    it 'audio カテゴリのアイコンを返す' do
      expect(helper.category_icon('audio')).to eq('🎧')
    end

    it 'conversation カテゴリのアイコンを返す' do
      expect(helper.category_icon('conversation')).to eq('💬')
    end

    it 'experience カテゴリのアイコンを返す' do
      expect(helper.category_icon('experience')).to eq('✨')
    end

    it 'observation カテゴリのアイコンを返す' do
      expect(helper.category_icon('observation')).to eq('👀')
    end

    it 'other カテゴリのアイコンを返す' do
      expect(helper.category_icon('other')).to eq('📁')
    end

    it '存在しないカテゴリはデフォルトアイコンを返す' do
      expect(helper.category_icon('invalid')).to eq('📁')
    end

    it 'nil入力でもデフォルトアイコンを返す（to_s安全）' do
      expect(helper.category_icon(nil)).to eq('📁')
    end

    it 'シンボルでも正しく動作する' do
      expect(helper.category_icon(:text)).to eq('📝')
    end
  end

  describe '#category_name_without_icon' do
    it 'カテゴリ名から絵文字を除去する' do
      # Post モデルの i18n 設定に依存するため、実際の値を確認
      result = helper.category_name_without_icon('text')
      expect(result).not_to include('📝')
      expect(result).to be_a(String)
      expect(result.length).to be > 0
    end

    it 'カテゴリ名を正しく取得する' do
      result = helper.category_name_without_icon('video')
      expect(result).not_to include('🎥')
      expect(result).to be_a(String)
    end

    it '絵文字が含まれていても除去される' do
      result = helper.category_name_without_icon('experience')
      expect(result).not_to match(/[📝🎥🎧💬✨👀📁]/)
    end

    it 'i18nに依存しない振る舞いを単体で検証（stub）' do
      # helper内で Post.human_attribute_name を通る前提の仕様を固定化
      allow(Post).to receive(:human_attribute_name)
        .with('category.text')
        .and_return('📝 テキスト ')
      expect(helper.category_name_without_icon('text')).to eq('テキスト')
    end
  end

  describe '#default_meta_tags' do
    before do
      # request オブジェクトをモック
      allow(helper).to receive(:request).and_return(
        double(
          original_url: 'http://example.com/test',
          base_url: 'http://example.com'
        )
      )
    end

    let(:meta) { helper.default_meta_tags }

    it 'サイト名を返す' do
      expect(meta[:site]).to eq('ActionSpark')
    end

    it 'タイトルを返す' do
      expect(meta[:title]).to eq('きっかけを行動に変える')
    end

    it 'ディスクリプションを返す' do
      expect(meta[:description]).to include('きっかけ')
      expect(meta[:description]).to include('行動')
    end

    it 'キーワードを返す' do
      expect(meta[:keywords]).to include('きっかけ')
    end

    it 'canonical URL を返す' do
      expect(meta[:canonical]).to eq('http://example.com/test')
    end

    it 'OG タグを含む（URL/画像/型）' do
      expect(meta[:og]).to be_a(Hash)
      expect(meta[:og][:site_name]).to eq('ActionSpark')
      expect(meta[:og][:type]).to eq('website')
      expect(meta[:og][:url]).to eq('http://example.com/test')
      expect(meta[:og][:image]).to eq('http://example.com/ogp-image.svg')
    end

    it 'Twitter カードタグを含む（画像URL含む）' do
      expect(meta[:twitter]).to be_a(Hash)
      expect(meta[:twitter][:card]).to eq('summary_large_image')
      expect(meta[:twitter][:image]).to eq('http://example.com/ogp-image.svg')
    end

    it 'メタの基本キー（reverse/charset/separator）を含む' do
      expect(meta[:reverse]).to eq(true)
      expect(meta[:charset]).to eq('utf-8')
      expect(meta[:separator]).to eq('|')
    end

    it 'OG/Twitter のタイトル・ディスクリプションはシンボル委譲である（view側で解決）' do
      expect(meta[:og][:title]).to eq(:title)
      expect(meta[:twitter][:title]).to eq(:title)
      expect(meta[:twitter][:description]).to eq(:description)
    end

    it 'ファビコン設定を含む（最低限のエントリ確認）' do
      expect(meta[:icon]).to be_an(Array)
      expect(meta[:icon].length).to be > 0
      # 最低限の存在チェック（過剰に厳密にしない）
      expect(meta[:icon]).to include(a_hash_including(href: '/favicon.ico'))
    end
  end
end
