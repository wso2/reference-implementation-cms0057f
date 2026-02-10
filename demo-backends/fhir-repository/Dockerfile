# Stage 1: Clone the repository
FROM alpine/git as clone
WORKDIR /app
RUN git clone -b fhir-server-v1 https://github.com/wso2/open-healthcare-prebuilt-services.git

# Stage 2: Run the server
FROM ballerina/ballerina:2201.12.3

USER root

# Copy the cloned repository from the previous stage
COPY --from=clone /app/open-healthcare-prebuilt-services/miscellaneous/fhir-server /home/ballerina/open-healthcare-prebuilt-services/miscellaneous/fhir-server

# Set the working directory to the FHIR server implementation
WORKDIR /home/ballerina/open-healthcare-prebuilt-services/miscellaneous/fhir-server

# Ensure script is executable and permissions are correct
RUN chmod +x start-server.sh && \
    chown -R 10500:10500 /home/ballerina

# Switch to non-root user
USER 10500
ENV HOME=/home/ballerina

EXPOSE 9090

CMD ["./start-server.sh"]
