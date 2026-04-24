FROM ruby:3.3-slim

RUN apt-get update && apt-get install -y \
  build-essential \
  git \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY Gemfile Gemfile.lock saturnci-sdk.gemspec ./
COPY lib/saturnci/version.rb lib/saturnci/version.rb
RUN bundle install && rm -rf /usr/local/bundle/cache/*
COPY . .
