FROM ruby:3.4.2-slim

RUN apt-get update && apt-get install -y \
  build-essential \
  git \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .
RUN gem build saturnci-sdk.gemspec \
  && gem install saturnci-sdk-*.gem \
  && rm -f saturnci-sdk-*.gem

ENTRYPOINT ["ruby", "-rsaturnci-sdk"]
