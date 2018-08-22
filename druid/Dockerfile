FROM ubuntu:14.04

ENV DRUID_VERSION 0.12.1
ENV ZOOKEEPER_VERSION 3.4.10

# Java 8
RUN apt-get update \
      && apt-get install -y software-properties-common \
      && apt-add-repository -y ppa:webupd8team/java \
      && apt-get purge --auto-remove -y software-properties-common \
      && apt-get update \
      && echo oracle-java-8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections \
      && apt-get install -y oracle-java8-installer oracle-java8-set-default \
                            mysql-server \
                            supervisor \
                            git \
      && apt-get clean \
      && rm -rf /var/cache/oracle-jdk8-installer \
      && rm -rf /var/lib/apt/lists/*


# Zookeeper
RUN wget -q -O - "http://www.us.apache.org/dist/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/zookeeper-${ZOOKEEPER_VERSION}.tar.gz" | tar -xzf - -C /usr/local \
      && cp "/usr/local/zookeeper-${ZOOKEEPER_VERSION}/conf/zoo_sample.cfg" "/usr/local/zookeeper-${ZOOKEEPER_VERSION}/conf/zoo.cfg" \
      && ln -s "/usr/local/zookeeper-${ZOOKEEPER_VERSION}" /usr/local/zookeeper

# Druid
RUN wget -q -O - "http://static.druid.io/artifacts/releases/druid-${DRUID_VERSION}-bin.tar.gz" | tar -xzf - -C /usr/local \
  && ln -s "/usr/local/druid-${DRUID_VERSION}" /usr/local/druid \
  && adduser --system --group --no-create-home druid \
  && mkdir -p "/var/lib/druid" \
  && chown druid:druid "/var/lib/druid"

WORKDIR "/usr/local/druid/"

RUN java \
      -cp "lib/*" \
      -Ddruid.extensions.directory="extensions" \
      -Ddruid.extensions.hadoopDependenciesDir="hadoop-dependencies" \
      io.druid.cli.Main tools pull-deps \
      -d ${DRUID_VERSION} \
      -c "io.druid.extensions.contrib:druid-azure-extensions" \
      -c "io.druid.extensions:mysql-metadata-storage"

# Setup metadata store and add sample data
RUN find /var/lib/mysql -type f -exec touch {} \; \
      && /etc/init.d/mysql start \
      && mysql -u root -e "GRANT ALL ON druid.* TO 'druid'@'localhost' IDENTIFIED BY 'druid'; CREATE database druid CHARACTER SET utf8;" \
      && java \
          -cp "/usr/local/druid/lib/*" \
          -Ddruid.extensions.directory="/usr/local/druid/extensions" \
          -Ddruid.extensions.hadoopDependenciesDir="/usr/local/druid/hadoop-dependencies" \
          -Ddruid.extensions.loadList=[\"mysql-metadata-storage\",\"druid-azure-extensions\"] \
          -Ddruid.metadata.storage.type=mysql \
          io.druid.cli.Main tools metadata-init \
              --connectURI="jdbc:mysql://localhost:3306/druid" \
              --user="druid" --password="druid" \
      && /etc/init.d/mysql stop

# Setup supervisord
ADD supervisord.conf "/etc/supervisor/conf.d/supervisord.conf"

# Cleanup
RUN apt-get clean \
  && rm -rf \
    "/tmp/*" \
    "/var/tmp/*" \
    "/var/cache/oracle-jdk8-installer" \
    "/var/lib/apt/lists/*"

# Expose ports:
# - 8081: HTTP (coordinator)
# - 8082: HTTP (broker)
# - 8083: HTTP (historical)
# - 8090: HTTP (overlord)
# - 3306: MySQL
# - 2181 2888 3888: ZooKeeper
EXPOSE 8081
EXPOSE 8082
EXPOSE 8083
EXPOSE 8090
EXPOSE 3306
EXPOSE 2181 2888 3888

WORKDIR "/var/lib/druid"
ENTRYPOINT export HOSTIP="$(resolveip -s $HOSTNAME)" && find /var/lib/mysql -type f -exec touch {} \; && exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf