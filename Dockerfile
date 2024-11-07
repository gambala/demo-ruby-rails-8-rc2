# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t demo_ruby_rails_8_rc2 .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name demo_ruby_rails_8_rc2 demo_ruby_rails_8_rc2

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.2.2
FROM docker.io/library/ruby:$RUBY_VERSION-alpine AS base
  # Rails app lives here
  WORKDIR /rails

  # Install base packages
  RUN apk add --no-cache jemalloc gcompat

  # Install tzinfo-data: assets:precompile and rails in boot time need it
  RUN apk add --no-cache tzdata

  # Set production environment
  ENV RAILS_ENV="production" \
      BUNDLE_DEPLOYMENT="1" \
      BUNDLE_PATH="/usr/local/bundle" \
      BUNDLE_WITHOUT="development:test"


FROM base AS build
  # Install packages needed to build gems
  RUN apk add --no-cache build-base git

  # Install application gems
  COPY Gemfile Gemfile.lock vendor ./

  RUN bundle install && \
      rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
      bundle exec bootsnap precompile --gemfile

  # Copy application code
  COPY . .

  # Precompile bootsnap code for faster boot times
  RUN bundle exec bootsnap precompile app/ lib/

  # Precompiling assets for production without requiring secret RAILS_MASTER_KEY
  RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile


FROM base
  # Copy built artifacts: gems, application
  COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
  COPY --from=build /rails /rails

  # Run and own only the runtime files as a non-root user for security
  RUN addgroup --system --gid 1000 rails && \
      adduser --system rails --uid 1000 --ingroup rails --home /home/rails --shell /bin/sh rails && \
      chown -R rails:rails db log storage tmp
  USER 1000:1000

  # Deployment options
  ENV LD_PRELOAD="libjemalloc.so.2" \
      MALLOC_CONF="dirty_decay_ms:1000,narenas:2,background_thread:true" \
      RUBY_YJIT_ENABLE="1"

  # Entrypoint prepares the database.
  ENTRYPOINT ["/rails/bin/docker-entrypoint"]

  EXPOSE 3000
  CMD ["bundle", "exec", "iodine", "-p", "3000", "-www", "/rails/public"]
