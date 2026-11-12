FROM ruby:3.4

ARG RACK_ENV
RUN mkdir /18xx
WORKDIR /18xx
RUN git config --global --add safe.directory /18xx

RUN curl -s https://registry.npmjs.org/esbuild-linux-64/-/esbuild-linux-64-0.14.36.tgz | tar xz && \
    mv package/bin/esbuild /usr/local/bin && rm -rf package

COPY Gemfile Gemfile.lock ./
RUN if [ "$RACK_ENV" = "production" ]; \
    then bundle config set without 'test development'; \
    fi; \
    bundle install;
COPY . .

RUN if [ "$RACK_ENV" = "production" ]; \
    then KEEP_ASSETS=true bundle exec rake precompile; \
    fi;

CMD bundle exec rake dev_up && \
    bundle exec rerun --background -i 'build/*' -i 'public/*' 'unicorn -c config/unicorn.rb'
