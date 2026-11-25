# Java-Bytecode ist portabel. Den Build nativ ausfuehren, auch bei amd64-Ziel auf ARM.
FROM --platform=$BUILDPLATFORM maven:3.9.11-eclipse-temurin-21@sha256:6fdc855a6ed81d288ca7ca37ac6ff5e9308b612485c0801d70b25a858c83d237 AS build
WORKDIR /build
COPY pom.xml .
RUN mvn --batch-mode --no-transfer-progress dependency:go-offline
COPY src ./src
# Tests gehoeren zum Build. Ein fehlerhaftes Image wird nicht erzeugt.
RUN mvn --batch-mode --no-transfer-progress verify

FROM eclipse-temurin:21-jre-jammy@sha256:dff6eb46527bd293a3c06bbbe9e64e8c9f91f01905b5abbdad31761c03059d2c
WORKDIR /app
COPY --from=build /build/target/hallo-app.jar ./app.jar
ARG APP_VERSION=1.0
ENV APP_VERSION=${APP_VERSION}
# Numerische UID funktioniert auch ohne Eintrag in /etc/passwd.
USER 10001:10001
EXPOSE 8080
# Heap nach dem Speicherlimit des Containers. Als Startargument statt als
# JAVA_TOOL_OPTIONS: sonst meldet die JVM bei jedem Start eine Zeile auf stderr,
# die im Logs Explorer als ERROR erscheint.
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=65.0", "-jar", "/app/app.jar"]
