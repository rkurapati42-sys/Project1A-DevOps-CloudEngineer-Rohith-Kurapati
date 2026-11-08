FROM eclipse-temurin:21-jre

USER root

RUN apt-get -o Acquire::Retries=0 update \
    && apt-get -o Acquire::Retries=0 upgrade -y \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY target/novapay-1.0.0.jar app.jar

EXPOSE 8080

USER 1001

ENTRYPOINT ["java", "-jar", "app.jar"]
