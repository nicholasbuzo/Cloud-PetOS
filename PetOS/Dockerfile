# ─────────────────────────────────────────────────────────────
# PetOS — Dockerfile
# Banco  : H2 modo arquivo — volume nomeado
# Usuário: petos (UID 1001, sem root)
# ─────────────────────────────────────────────────────────────

FROM maven:3.9-eclipse-temurin-17-alpine

LABEL maintainer="rm561082@fiap.com.br"
LABEL description="PetOS - API de Saúde Animal - Java 17 + Spring Boot 3 + H2"

# Instala curl para o health check
RUN apk add --no-cache curl

# Cria usuário sem privilégios (UID 1001)
RUN addgroup -S petos && adduser -S petos -G petos -u 1001

WORKDIR /app

# Copia pom.xml primeiro (cache de dependências)
COPY pom.xml ./
RUN mvn dependency:go-offline -q

# Copia o código e gera o JAR
COPY src ./src
RUN mvn package -DskipTests -q

# Cria diretório para o banco H2
RUN mkdir -p /app/data && chown -R petos:petos /app

# Copia o JAR para local limpo
RUN cp target/*.jar app.jar && chown petos:petos app.jar

# Usuário sem privilégios
USER petos

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", \
  "-Djava.security.egd=file:/dev/./urandom", \
  "-Dspring.profiles.active=prod", \
  "-Dspring.datasource.url=jdbc:h2:file:/app/data/petosdb;AUTO_SERVER=TRUE", \
  "-jar", "app.jar"]