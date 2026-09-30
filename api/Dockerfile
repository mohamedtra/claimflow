# syntax=docker/dockerfile:1
# Contexte de build : racine du dépôt (le contrat OpenAPI est dans docs/).
FROM maven:3.9-eclipse-temurin-25 AS build
WORKDIR /workspace
COPY api/pom.xml api/pom.xml
RUN --mount=type=cache,target=/root/.m2 mvn -B -q -f api/pom.xml dependency:go-offline
COPY docs/openapi docs/openapi
COPY api/src api/src
RUN --mount=type=cache,target=/root/.m2 mvn -B -q -f api/pom.xml package -DskipTests \
    && java -Djarmode=tools -jar api/target/claimflow-api.jar extract --layers --launcher --destination extrait

FROM eclipse-temurin:25-jre
RUN groupadd --system claimflow && useradd --system --gid claimflow --no-create-home claimflow
WORKDIR /app
# Couches de la moins à la plus changeante : les dépendances restent en cache entre deux builds.
COPY --from=build /workspace/extrait/dependencies/ ./
COPY --from=build /workspace/extrait/spring-boot-loader/ ./
COPY --from=build /workspace/extrait/snapshot-dependencies/ ./
COPY --from=build /workspace/extrait/application/ ./
USER claimflow
EXPOSE 8080
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "org.springframework.boot.loader.launch.JarLauncher"]
