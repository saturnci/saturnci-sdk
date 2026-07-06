FROM ruby:4.0.1-slim AS builder

RUN apt-get update && apt-get install -y \
  git \
  && rm -rf /var/lib/apt/lists/*

ARG SDK_COMMIT=7892778
RUN git clone https://github.com/saturnci/saturnci-sdk.git /tmp/saturnci-sdk \
  && cd /tmp/saturnci-sdk \
  && git checkout $SDK_COMMIT \
  && gem build saturnci-sdk.gemspec

FROM ruby:4.0.1-slim

RUN apt-get update && apt-get install -y \
  git \
  && rm -rf /var/lib/apt/lists/*

COPY --from=builder /tmp/saturnci-sdk/saturnci-sdk-*.gem /tmp/
RUN gem install /tmp/saturnci-sdk-*.gem && rm /tmp/saturnci-sdk-*.gem

ENTRYPOINT ["ruby", "-rsaturnci-sdk"]
