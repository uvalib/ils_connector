FROM ruby:2.4.2-stretch

RUN apt-get update -qq && apt-get install -y build-essential mysql-client

RUN chmod 777 -R /tmp && chmod o+t -R /tmp
ENV APP_HOME /ils_connector
ENV RAILS_ENV production
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

ADD Gemfile $APP_HOME/Gemfile
ADD Gemfile.lock $APP_HOME/Gemfile.lock
RUN bundle install

ADD . $APP_HOME

#RUN rake assets:precompile
