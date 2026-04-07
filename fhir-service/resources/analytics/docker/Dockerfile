FROM --platform=linux/amd64 ubuntu:24.04

RUN groupadd -g 10001 choreo && \
    useradd -u 10001 -g choreo -s /usr/sbin/nologin -M choreo

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        openjdk-21-jdk \
        wget \
        gnupg \
        curl \
        ca-certificates \
        git \
    && wget https://dist.ballerina.io/downloads/2201.12.11/ballerina-2201.12.11-swan-lake-linux-x64.deb \
    && dpkg -i ballerina-2201.12.11-swan-lake-linux-x64.deb \
    && rm ballerina-2201.12.11-swan-lake-linux-x64.deb \
    && sh -c 'curl https://packages.fluentbit.io/fluentbit.key | gpg --dearmor > /usr/share/keyrings/fluentbit-keyring.gpg' \
    && curl https://raw.githubusercontent.com/fluent/fluent-bit/master/install.sh | sh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch main https://github.com/wso2/reference-implementation-cms0057f.git && \
    cd reference-implementation-cms0057f/fhir-service && \
    bal build && \
    mkdir -p /home/ballerina && \
    cp target/bin/fhir.service.jar /home/ballerina/fhir.service.jar && \
    chown -R 10001:choreo /home/ballerina && \
    rm -rf /reference-implementation-cms0057f

USER 10001

WORKDIR /home/ballerina

COPY --chown=10001:choreo entrypoint.sh /home/ballerina/entrypoint.sh
RUN chmod +x /home/ballerina/entrypoint.sh

ENTRYPOINT ["/home/ballerina/entrypoint.sh"]
