FROM --platform=linux/amd64 ubuntu:24.04

RUN groupadd -g 10001 choreo && \
    useradd -u 10001 -g choreo -s /usr/sbin/nologin -M choreo

RUN apt-get update \
    && apt-get install -y openjdk-21-jdk \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
    && apt-get install -y --no-install-recommends wget \
    && wget https://dist.ballerina.io/downloads/2201.12.3/ballerina-2201.12.3-swan-lake-linux-x64.deb \
    && dpkg -i ballerina-2201.12.3-swan-lake-linux-x64.deb \
    && rm ballerina-2201.12.3-swan-lake-linux-x64.deb \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
    && apt-get install -y --no-install-recommends gnupg curl \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
    && sh -c 'curl https://packages.fluentbit.io/fluentbit.key | gpg --dearmor > /usr/share/keyrings/fluentbit-keyring.gpg' \
    && curl https://raw.githubusercontent.com/fluent/fluent-bit/master/install.sh | sh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER 10001

WORKDIR /home/ballerina

# COPY --chown=10001:choreo fhir.service.jar /home/ballerina

COPY --chown=10001:choreo entrypoint.sh /home/ballerina/entrypoint.sh
RUN chmod +x /home/ballerina/entrypoint.sh

ENTRYPOINT ["/home/ballerina/entrypoint.sh"]
