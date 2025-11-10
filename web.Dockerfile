FROM ubuntu:plucky

# use bash as the default shell
SHELL ["/bin/bash", "-lc"]

# install required packages
RUN apt update && apt install -y \ 
    apache2 \
    apache2-dev \
    git \
    software-properties-common \
    libmysqlclient-dev \
    libcap-dev \
    apt-transport-https \
    postgresql \
    postgresql-server-dev-all \
    zip \
    unzip && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# install RVM
RUN apt-add-repository -y ppa:rael-gc/rvm && \
    apt update && \
    apt install -y rvm && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# clone cafe-grader-web
RUN git clone https://github.com/nattee/cafe-grader-web.git /cafe-grader/web

# fallback if the latest version of cafe-grader-web is not compatible
# COPY cafe-grader-web /cafe-grader/web

# install Ruby version from .ruby-version file and install gems
RUN RUBY_VERSION=$(cat /cafe-grader/web/.ruby-version | tr -d '[:space:]') && \
    echo "Installing Ruby ${RUBY_VERSION}..." && \
    /bin/bash -lc "rvm install ${RUBY_VERSION}" && \
    /bin/bash -lc "rvm use ${RUBY_VERSION}"

# bundle install
WORKDIR /cafe-grader/web
RUN bundle

# copy configuration files from samples and process environment variables
RUN cp config/application.rb.SAMPLE config/application.rb && \
    cp config/database.yml.SAMPLE config/database.yml && \
    cp config/worker.yml.SAMPLE config/worker.yml

# process application.rb to use environment variable for timezone
RUN sed -i 's/config\.time_zone = "Asia\/Bangkok"/config.time_zone = ENV.fetch("RAILS_TIME_ZONE", "Asia\/Bangkok")/' /cafe-grader/web/config/application.rb && \
    sed -i 's/username: grader/username: <%= ENV.fetch("MYSQL_USER", "grader_user") %>/' /cafe-grader/web/config/database.yml && \
    sed -i 's/password: grader/password: <%= ENV.fetch("MYSQL_PASSWORD", "grader_pass") %>/' /cafe-grader/web/config/database.yml && \
    sed -i 's/host: localhost/host: <%= ENV.fetch("SQL_DATABASE_CONTAINER_HOST", "cafe-grader-db") %>/' /cafe-grader/web/config/database.yml && \
    sed -i 's/socket: \/var\/run\/mysqld\/mysqld\.sock/port: <%= ENV.fetch("SQL_DATABASE_PORT", "3306") %>/' /cafe-grader/web/config/database.yml && \
    sed -i 's@| Revision: #{APP_VERSION}#{APP_VERSION_SUFFIX}@& (#{link_to "Docker", "https://github.com/folkiesss/cafe-grader-docker"})@' /cafe-grader/web/app/views/layouts/application.html.haml

# install nodejs 22.x
RUN curl -sL https://deb.nodesource.com/setup_22.x -o /tmp/nodesource_setup.sh && \
    bash /tmp/nodesource_setup.sh && \
    apt install -y nodejs && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /tmp/nodesource_setup.sh

# install and enable Yarn
RUN corepack enable && \
    corepack prepare yarn@stable --activate && \
    yarn

RUN rm -rf /tmp/* /var/tmp/* ~/.cache