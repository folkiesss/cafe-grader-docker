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
    sed -i 's|web: http://localhost|web: http://cafe-grader-web:3000|' config/worker.yml

# return to home directory
WORKDIR /

# install IOI Isolate
RUN apt install -y libcap-dev libsystemd-dev && \
    git clone https://github.com/ioi/isolate.git /tmp/isolate && \
    cd /tmp/isolate && make isolate && make install && \
    rm -rf /tmp/* /var/tmp/* ~/.cache

# install programming language compilers and runtimes
RUN apt install -y ghc g++ openjdk-21-jdk fpc php-cli php-readline golang-go cargo python3-venv && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# set up Python virtual environment for grader
RUN python3 -m venv /venv/grader

# add cron job to clean up isolate_submission directory
RUN apt update && apt install -y cron && \
    echo "0 2 * * * find /cafe-grader/judge/isolate_submission/ -maxdepth 1 -mtime +1 -exec rm -rf {} \\;" | crontab - && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# copy systemd service files
COPY services/*.service /etc/systemd/system/

RUN systemctl enable isolate set-ioi-isolate && \
    systemctl enable isolate && \
    systemctl enable solid_queue && \
    systemctl enable grader_worker

# copy start script and make it executable
COPY scripts/entrypoint.sh cafe-grader/scripts/
COPY scripts/start_worker.sh cafe-grader/scripts/
RUN chmod +x \
    cafe-grader/scripts/entrypoint.sh \
    cafe-grader/scripts/start_worker.sh

# clean up apt cache and temporary files to reduce image size
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# set working directory and entrypoint
WORKDIR /cafe-grader/scripts
ENTRYPOINT ["./entrypoint.sh"]