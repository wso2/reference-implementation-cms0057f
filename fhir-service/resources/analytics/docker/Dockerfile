FROM --platform=linux/amd64 ubuntu:24.04

ARG BALLERINA_VERSION=2201.12.11

RUN groupadd -g 10001 choreo && \
    useradd -u 10001 -g choreo -s /usr/sbin/nologin -M choreo

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates gnupg curl git wget openjdk-21-jdk \
    && wget https://dist.ballerina.io/downloads/${BALLERINA_VERSION}/ballerina-${BALLERINA_VERSION}-swan-lake-linux-x64.deb \                                                     
    && dpkg -i ballerina-${BALLERINA_VERSION}-swan-lake-linux-x64.deb \                                                                                                           
    && rm ballerina-${BALLERINA_VERSION}-swan-lake-linux-x64.deb \
    && mkdir -p /usr/share/keyrings \
    && tmpkey="$(mktemp)" \
    && curl -fsSL -o "$tmpkey" https://packages.fluentbit.io/fluentbit.key \
    && gpg --dearmor --batch --yes -o /usr/share/keyrings/fluentbit-keyring.gpg "$tmpkey" \
    && rm -f "$tmpkey" \
    && echo "deb [signed-by=/usr/share/keyrings/fluentbit-keyring.gpg] https://packages.fluentbit.io/ubuntu/noble noble main" \
       | tee /etc/apt/sources.list.d/fluent-bit.list > /dev/null \
    && printf 'Package: fluent-bit\nPin: origin "packages.fluentbit.io"\nPin-Priority: 1001\n' \
       > /etc/apt/preferences.d/fluent-bit.pref \
    && apt-get update \
    && apt-get install -y --no-install-recommends fluent-bit \
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
