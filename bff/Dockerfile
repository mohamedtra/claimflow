# syntax=docker/dockerfile:1
# Contexte de build : racine du dépôt, comme pour l'API.
FROM maven:3.9-eclipse-temurin-25 AS build
WORKDIR /workspace
COPY bff/pom.xml bff/pom.xml
RUN --mount=type=cache,target=/root/.m2 mvn -B -q -f bff/pom.xml dependency:go-offline
COPY bff/src bff/src
RUN --mount=type=cache,target=/root/.m2 mvn -B -q -f bff/pom.xml package -DskipTests \
    && java -Djarmode=tools -jar bff/target/claimflow-bff.jar extract --layers --launcher --destination extrait

FROM eclipse-temurin:25-jre
RUN groupadd --system claimflow && useradd --system --gid claimflow --no-create-home claimflow
WORKDIR /app
COPY --from=build /workspace/extrait/dependencies/ ./
COPY --from=build /workspace/extrait/spring-boot-loader/ ./
COPY --from=build /workspace/extrait/snapshot-dependencies/ ./
COPY --from=build /workspace/extrait/application/ ./
USER claimflow
EXPOSE 8080
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "org.springframework.boot.loader.launch.JarLauncher"]
