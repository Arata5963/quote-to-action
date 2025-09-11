# Rubyバージョンを変数として定義
ARG RUBY_VERSION=3.3.9

# Ruby公式のslimイメージをベースとして使用（軽量版）
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# コンテナ内の作業ディレクトリを/railsに設定
WORKDIR /rails

# 本番環境で必要なランタイムパッケージをインストール
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    # HTTP通信用
    curl \
    # SSL証明書（S3のHTTPS通信に必要）
    ca-certificates \
    # メモリアロケータ（パフォーマンス向上）
    libjemalloc2 \
    # 画像処理ライブラリ
    libvips \
    # mini_magickの依存関係
    imagemagick \
    # PostgreSQL接続用ランタイムライブラリ
    libpq5 \
    # SSL証明書を更新
    && update-ca-certificates && \
    # キャッシュクリア（イメージサイズ削減）
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# 本番環境用の環境変数を設定
# Rails実行環境を本番モードに設定
ENV RAILS_ENV="production" \
    # Bundlerをデプロイメントモードで実行
    BUNDLE_DEPLOYMENT="1" \
    # Gemのインストール先を指定
    BUNDLE_PATH="/usr/local/bundle" \
    # 開発・テスト用gemを除外
    BUNDLE_WITHOUT="development test" \
    # 静的ファイル（CSS/JS）をRailsで配信
    RAILS_SERVE_STATIC_FILES="1"

# ビルドステージ：アプリケーションのビルドに必要なツールをインストール
FROM base AS build

# ビルド用パッケージをインストール（コンパイルに必要）
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    # C/C++コンパイラ等
    build-essential \
    # Gitクライアント
    git \
    # YAML処理ライブラリ（開発版）
    libyaml-dev \
    # パッケージ設定ツール
    pkg-config \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# GemfileとGemfile.lockをコピーしてgemをインストール
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    # Bootsnapプリコンパイル（起動高速化）
    bundle exec bootsnap precompile --gemfile

# アプリケーションコード全体をコピー
COPY . .

# アプリケーションコードをBootsnapでプリコンパイル
RUN bundle exec bootsnap precompile app/ lib/

# アセット（CSS/JS）をプリコンパイル（ダミーキーで実行）
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# 最終ステージ：本番用の軽量イメージを作成
FROM base

# ビルドステージからgemとアプリケーションをコピー
# インストール済みgem
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
# アプリケーションコード
COPY --from=build /rails /rails

# セキュリティ：非rootユーザーでアプリケーションを実行
# railsグループを作成
RUN groupadd --system --gid 1000 rails && \
    # railsユーザーを作成
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    # 必要なディレクトリの所有権を変更
    chown -R rails:rails db log storage tmp
# railsユーザーに切り替え
USER 1000:1000

# データベース準備等を行うエントリーポイントを設定
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Render対応：動的に割り当てられるPORTでサーバーを起動
# ポート3000を公開
EXPOSE 3000
# PORT環境変数対応
CMD ["bash", "-c", "bin/rails server -b 0.0.0.0 -p ${PORT:-3000}"]