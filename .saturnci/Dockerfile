FROM ruby:3.3-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock saturnci-sdk.gemspec ./
COPY lib/saturnci/version.rb lib/saturnci/version.rb
RUN bundle install && rm -rf /usr/local/bundle/cache/*

COPY . .
