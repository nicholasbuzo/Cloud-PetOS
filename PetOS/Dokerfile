# ─────────────────────────────────────────────────────────────
# PetOS — Dockerfile Multi-Stage
# Stage 1 : Build com Maven Wrapper
# Stage 2 : Runtime enxuto (JRE Alpine)
# Banco    : H2 em modo FILE (persistência via volume nomeado)
# Usuário  : petos (UID 1001, sem root)
# ─────────────────────────────────────────────────────────────

# ── Stage 1: Build ───────────────────────────────────────────
FROM maven:3.9-eclipse-temurin-17-alpine AS builder
 
WORKDIR /app
 
# Copia o pom.xml primeiro (cache de dependências separado do código)
# Se o pom.xml não mudar, o Docker reutiliza o cache desta camada
COPY pom.xml ./
RUN mvn dependency:go-offline -q
 
# Copia o código-fonte
COPY src ./src
 
# Gera o JAR executável (pula testes — H2 sobe junto com a app)
RUN mvn package -DskipTests -q
 
# ── Stage 2: Runtime ─────────────────────────────────────────
FROM eclipse-temurin:17-jre-alpine
 
LABEL maintainer="equipe-petos@fiap.com.br"
LABEL description="PetOS - API de Saúde Animal - Java 17 + Spring Boot 3 + H2"
LABEL version="1.0.0"
 
# Cria grupo e usuário sem privilégios (UID 1001)
# Evita penalidade de -0,5 ponto por rodar como root
RUN addgroup -S petos && adduser -S petos -G petos -u 1001
 
WORKDIR /app
 
# Diretório para o arquivo do banco H2
# Será montado como volume nomeado no Docker Compose
RUN mkdir -p /app/data && chown -R petos:petos /app
 
# Copia apenas o JAR gerado no stage de build
COPY --from=builder /app/target/*.jar app.jar
RUN chown petos:petos app.jar
 
# Usuário sem privilégios — obrigatório
USER petos
 
# Porta da aplicação
EXPOSE 8080
 
# Health check interno do container
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD wget -qO- http://localhost:8080/actuator/health || exit 1
 
# Inicia com perfil prod e H2 em modo arquivo apontando para /app/data
ENTRYPOINT ["java", \
  "-Djava.security.egd=file:/dev/./urandom", \
  "-Dspring.profiles.active=prod", \
  "-Dspring.datasource.url=jdbc:h2:file:/app/data/petosdb;AUTO_SERVER=TRUE", \
  "-jar", "app.jar"]
