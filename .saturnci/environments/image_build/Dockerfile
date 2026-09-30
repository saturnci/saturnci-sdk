FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
  curl \
  git \
  ruby \
  ruby-dev \
  docker.io \
  && rm -rf /var/lib/apt/lists/*

# The job script talks to the SaturnCI API, so it needs the SDK -- the same one
# this repository publishes, built from the checked-out source.
COPY . /tmp/saturnci-sdk
RUN cd /tmp/saturnci-sdk \
  && gem build saturnci-sdk.gemspec \
  && gem install saturnci-sdk-*.gem \
  && rm -rf /tmp/saturnci-sdk

ENTRYPOINT ["ruby", "-rsaturnci-sdk"]
