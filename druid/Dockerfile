FROM ubuntu:14.04

ENV DRUID_VERSION '0.12.2'
ENV DRUID_HOME '/usr/local/druid'
ENV DRUID_LOGS '/var/lib/druid'
ENV DRUID_TMP '/tmp/druid/'

#####################
# Environment Setup #
#####################

# Java 8
RUN apt-get update \
      && apt-get install -y software-properties-common \
      && apt-add-repository -y ppa:webupd8team/java \
      && apt-get purge --auto-remove -y software-properties-common \
      && apt-get update \
      && echo oracle-java-8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections \
      && apt-get install -y oracle-java8-installer oracle-java8-set-default \
                            gettext-base \
                            supervisor \
                            nano \
                            curl \
      && apt-get clean \
      && rm -rf /var/cache/oracle-jdk8-installer \
      && rm -rf /var/lib/apt/lists/*

# Druid
RUN wget -q -O - "http://static.druid.io/artifacts/releases/druid-${DRUID_VERSION}-bin.tar.gz" | tar -xzf - -C /usr/local \
  && ln -s "/usr/local/druid-${DRUID_VERSION}" ${DRUID_HOME} \
  && adduser --system --group --no-create-home druid \
  && wget -q -O - "https://github.com/Microsoft/mssql-jdbc/releases/download/v7.0.0/mssql-jdbc-7.0.0.jre8.jar" -O "${DRUID_HOME}/lib/mssql-jdbc-7.0.0.jre8.jar" \
  && mkdir -p ${DRUID_LOGS} \
  && chown druid:druid ${DRUID_LOGS}

WORKDIR ${DRUID_HOME}
RUN java \
      -cp "lib/*" \
      -Ddruid.extensions.directory="extensions" \
      -Ddruid.extensions.hadoopDependenciesDir="hadoop-dependencies" \
      io.druid.cli.Main tools pull-deps \
      -d ${DRUID_VERSION} \
      -c "io.druid.extensions.contrib:druid-azure-extensions" \
      -c "io.druid.extensions.contrib:sqlserver-metadata-storage"

# Cleanup
RUN apt-get clean \
  && rm -rf \
    "/tmp/*" \
    "/var/tmp/*" \
    "/var/cache/oracle-jdk8-installer" \
    "/var/lib/apt/lists/*"


#############################
# Environment Configuration #
#############################

ENV NODE_TYPE 'single'
ENV AZURE_ACCOUNT ''
ENV AZURE_KEY ''
ENV AZURE_CONTAINER ''
ENV METADATA_DB_TYPE 'type'
ENV METADATA_DB_URL 'jdbc:mysql://localhost:3306/druid'
ENV METADATA_DB_USER 'druid'
ENV METADATA_DB_PASSWORD 'druid'
ENV ZOOKEEPER_HOSTS 'localhost'

COPY supervisord-single.conf "/etc/supervisor/conf.d/supervisord-single.conf"
COPY supervisord-broker.conf "/etc/supervisor/conf.d/supervisord-broker.conf"
COPY supervisord-historical.conf "/etc/supervisor/conf.d/supervisord-historical.conf"
COPY supervisord-coordinator.conf "/etc/supervisor/conf.d/supervisord-coordinator.conf"
COPY log4j2.xml "$DRUID_HOME/conf/druid/_common/log4j2.xml"

# Expose ports:
# - 8081: HTTP (coordinator)
# - 8082: HTTP (broker)
# - 8083: HTTP (historical)
# - 8090: HTTP (overlord)

EXPOSE 8081
EXPOSE 8082
EXPOSE 8083
EXPOSE 8090
EXPOSE 22

WORKDIR ${DRUID_LOGS}
ENTRYPOINT export HOSTIP="$(resolveip -s $HOSTNAME)" \
        && exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord-${NODE_TYPE}.conf