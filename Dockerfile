FROM ruby:3.2

WORKDIR /app
COPY . /app

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev
RUN gem install bundler
RUN bundle install

CMD ["rackup", "-s", "puma", "-o", "0.0.0.0"]
