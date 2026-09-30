# The image every SaturnCI workflow runs in. It carries one thing that varies:
# the SDK, at the version this repository is currently at.
FROM ruby:4.0.1-slim

RUN apt-get update && apt-get install -y \
  git \
  && rm -rf /var/lib/apt/lists/*

COPY . /tmp/saturnci-sdk
RUN cd /tmp/saturnci-sdk \
  && gem build saturnci-sdk.gemspec \
  && gem install saturnci-sdk-*.gem \
  && rm -rf /tmp/saturnci-sdk

ENTRYPOINT ["ruby", "-rsaturnci-sdk"]
