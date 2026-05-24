# 🐾 PetOS — API de Saúde Animal

> **FIAP** × **CLYVO VET** — Plataforma de cuidado contínuo para pets.  
> Backend em **Java 17 + Spring Boot 3**, banco **H2**, containerizado com **Docker** e hospedado na **Azure**.

---

## 📋 Índice

1. [Descrição do Projeto](#1-descrição-do-projeto)
2. [Benefícios para o Negócio](#2-benefícios-para-o-negócio)
3. [Arquitetura Macro na Nuvem](#3-arquitetura-macro-na-nuvem)
4. [Rotas da API](#4-rotas-da-api)
5. [Instalação — How To](#5-instalação--how-to)
6. [Dockerfile](#6-dockerfile)
7. [Docker Compose](#7-docker-compose)
8. [Script Azure CLI](#8-script-azure-cli)
9. [Equipe](#9-equipe)

---

## 1. Descrição do Projeto

O **PetOS** centraliza o histórico de saúde, vacinas, rotinas e alertas dos pets, permitindo que tutores e clínicas veterinárias acompanhem a saúde dos animais de forma **longitudinal e contínua**, com notificações automáticas de vacinas vencidas ou próximas do vencimento.

**Stack:**

| Tecnologia | Versão |
|-----------|--------|
| Java | 17 |
| Spring Boot | 3.4.4 |
| Spring Data JPA | — |
| Spring Cache | — |
| **H2 Database** | — |
| SpringDoc OpenAPI | 2.8.6 |
| Lombok | 1.18.38 |
| Docker | 24+ |
| Azure VM | Ubuntu 22.04 |

**Entidades do domínio:**
- **Pet** — cadastro com espécie, raça, peso e soft delete
- **Vaccine** — registro de vacinas com status automático (`PENDING`, `APPLIED`, `EXPIRING_SOON`, `OVERDUE`)
- **Routine** — rotinas do pet (passeio, medicação, banho etc.)
- **Alert** — alertas preventivos gerados automaticamente ao registrar vacinas

---

## 2. Benefícios para o Negócio

| Benefício | Impacto |
|-----------|---------|
| **Histórico longitudinal unificado** | Tutor e veterinário têm visão completa da saúde do pet em uma chamada |
| **Alertas automáticos de vacinas** | Ao registrar vacina com vencimento futuro, alerta é gerado sem intervenção manual |
| **Status calculado de vacinas** | Sistema classifica automaticamente: `PENDING → APPLIED → EXPIRING_SOON → OVERDUE` |
| **Soft delete de pets** | Dados históricos preservados mesmo após "exclusão", garantindo rastreabilidade |
| **Cache integrado** | Spring Cache reduz latência em consultas frequentes de histórico |
| **API documentada** | Swagger UI facilita integração com app mobile e portal da clínica |
| **Containerização H2** | Banco leve, sem dependência externa, persistido via volume Docker nomeado |

---

## 3. Arquitetura Macro na Nuvem

```
┌────────────────────────────────────────────────────────────────┐
│                    MICROSOFT AZURE — East US                   │
│                                                                │
│   ┌────────────────────────────────────────────────────────┐   │
│   │      VM Ubuntu 22.04 LTS — vm-petos (Standard_B2s)     │   │
│   │      NSG: 22 (SSH) | 80 (HTTP) | 8080 (API)            │   │
│   │                                                        │   │
│   │   ┌────────────────────────────────────────────────┐   │   │
│   │   │  Container: petos-api                          │   │   │
│   │   │                                                │   │   │
│   │   │  Spring Boot 3 + Java 17                       │   │   │
│   │   │  H2 Database (modo arquivo)                    │   │   │
│   │   │  Porta 8080                                    │   │   │
│   │   │  USER: petos (UID 1001, sem root)              │   │   │
│   │   │                                                │   │   │
│   │   │  /app/data/petosdb.mv.db ──────────────────┐   │   │   │
│   │   └────────────────────────────────────────────│───┘   │   │
│   │                                                │       │   │
│   │   ┌─────────────────────────────────────────── ▼ ──┐   │   │
│   │   │  Volume Nomeado: petos_h2_data                 │   │   │
│   │   │  → /app/data (arquivo petosdb.mv.db persiste)  │   │   │
│   │   └────────────────────────────────────────────────┘   │   │
│   └────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────┘
           ▲
           │  HTTP/REST (JSON)  porta 8080
           │
  ┌────────┴──────────────┐
  │  Cliente Externo      │
  │  Postman / curl /     │
  │  Swagger UI           │
  └───────────────────────┘
```

**Fluxo de requisição:**
```
Cliente → NSG Azure (8080) → VM → Container petos-api
        → Spring Boot → H2 (arquivo em /app/data)
        → Volume petos_h2_data (persiste no disco da VM)
        → Resposta JSON ao cliente
```

---

## 4. Rotas da API

### 🐶 Pet

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/pets` | Listar pets ativos (paginado) |
| `GET` | `/pets/{id}` | Buscar pet por ID |
| `GET` | `/pets/search?name=` | Buscar por nome |
| `GET` | `/pets/species/{species}` | Filtrar por espécie |
| `GET` | `/pets/{id}/history` | Histórico consolidado (vacinas + rotinas + alertas) |
| `GET` | `/pets/vaccines/expiring` | Pets com vacinas vencidas ou próximas |
| `POST` | `/pets` | Cadastrar pet |
| `PUT` | `/pets/{id}` | Atualizar pet |
| `DELETE` | `/pets/{id}` | Inativar pet (soft delete) |

### 💉 Vaccine

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/vaccines` | Listar todas (paginado) |
| `GET` | `/vaccines/{id}` | Buscar por ID |
| `GET` | `/pets/{petId}/vaccines` | Vacinas do pet |
| `GET` | `/pets/{petId}/vaccines/pending` | Vacinas pendentes |
| `POST` | `/vaccines` | Registrar vacina *(gera alerta automático)* |
| `PUT` | `/vaccines/{id}` | Atualizar vacina |
| `DELETE` | `/vaccines/{id}` | Remover vacina |

### 📅 Routine

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/routines` | Listar todas (paginado) |
| `GET` | `/routines/{id}` | Buscar por ID |
| `GET` | `/pets/{petId}/routines` | Rotinas do pet |
| `POST` | `/routines` | Registrar rotina |
| `PUT` | `/routines/{id}` | Atualizar rotina |
| `DELETE` | `/routines/{id}` | Remover rotina |

### 🔔 Alert

| Método | Rota | Descrição |
|--------|------|-----------|
| `GET` | `/alerts` | Listar todos (paginado) |
| `GET` | `/alerts/{id}` | Buscar por ID |
| `GET` | `/alerts/pending` | Todos os alertas pendentes |
| `GET` | `/pets/{petId}/alerts` | Alertas do pet |
| `GET` | `/pets/{petId}/alerts/pending` | Alertas pendentes do pet |
| `POST` | `/alerts` | Criar alerta manual |
| `PUT` | `/alerts/{id}` | Atualizar alerta |
| `PATCH` | `/alerts/{id}/mark-sent` | Marcar alerta como enviado |
| `DELETE` | `/alerts/{id}` | Remover alerta |

### 🔎 Swagger & H2

| URL | Descrição |
|-----|-----------|
| `http://<HOST>:8080/swagger-ui.html` | Documentação interativa da API |
| `http://<HOST>:8080/api-docs` | OpenAPI JSON |
| `http://<HOST>:8080/h2-console` | Console web do banco H2 |
| `http://<HOST>:8080/actuator/health` | Health check |

**Acesso ao H2 Console:**
- JDBC URL: `jdbc:h2:file:/app/data/petosdb`
- Usuário: `sa`
- Senha: *(vazio)*

---

## 5. Instalação — How To

### Pré-requisitos

- [Docker](https://docs.docker.com/get-docker/) 24+
- [Docker Compose Plugin](https://docs.docker.com/compose/)
- [Git](https://git-scm.com/)
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) *(deploy em nuvem)*

---
### Deploy na Azure

```bash
# 1. Login na Azure
az login

# 2. Executar script de provisionamento
chmod +x azure-setup.sh
./azure-setup.sh
# Anote o IP exibido ao final

# 3. Conectar na VM
ssh petosadmin@<VM_IP>

# 4. Clonar repositório na VM
cd /opt/petos
git clone https://github.com/nicholasbuzo/Cloud-PetOS.git .

# 5. Subir em background
docker compose up -d --build
```

---

## 6. Dockerfile

```dockerfile
FROM maven:3.9-eclipse-temurin-17-alpine AS builder
WORKDIR /app
COPY pom.xml ./
RUN mvn dependency:go-offline -q
COPY src ./src
RUN mvn package -DskipTests -q

FROM eclipse-temurin:17-jre-alpine
RUN addgroup -S petos && adduser -S petos -G petos -u 1001
WORKDIR /app
RUN mkdir -p /app/data && chown -R petos:petos /app
COPY --from=builder /app/target/*.jar app.jar
RUN chown petos:petos app.jar
USER petos
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD wget -qO- http://localhost:8080/actuator/health || exit 1
ENTRYPOINT ["java", \
  "-Dspring.profiles.active=prod", \
  "-Dspring.datasource.url=jdbc:h2:file:/app/data/petosdb;AUTO_SERVER=TRUE", \
  "-jar", "app.jar"]
```

---

## 7. Docker Compose

```yaml
version: "3.9"
services:
  petos-api:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: petos-api
    restart: unless-stopped
    environment:
      SPRING_DATASOURCE_URL: jdbc:h2:file:/app/data/petosdb;AUTO_SERVER=TRUE
      SPRING_DATASOURCE_USERNAME: sa
      SPRING_DATASOURCE_PASSWORD: ""
      SPRING_JPA_HIBERNATE_DDL_AUTO: update
      SPRING_H2_CONSOLE_ENABLED: "true"
      SPRING_H2_CONSOLE_SETTINGS_WEB_ALLOW_OTHERS: "true"
      SPRING_PROFILES_ACTIVE: prod
    ports:
      - "8080:8080"
    volumes:
      - petos_h2_data:/app/data
    user: "1001"

volumes:
  petos_h2_data:
    name: petos_h2_data
```

---

## 8. Script Azure CLI

O script `azure-setup.sh` executa em sequência:

1. **Resource Group** `rg-petos` criado em `eastus`
2. **VM** Ubuntu 22.04 LTS — `Standard_B2s` (2 vCPU, 4 GB RAM)
3. **Portas** abertas no NSG: 22, 80, 8080
4. **Instalação**: Docker Engine, Docker Compose Plugin, Git, nano...

---

## 9. Demonstração por vídeo
Vídeo com demonstração por voz do funcionamento do projeto

[![Demonstração explicada](https://img.youtube.com/vi/XhzemOZKGtc/0.jpg)](https://youtu.be/XhzemOZKGtc)

---

## 10. Equipe

| Nome | RM |
|------|----|
| Gustavo Gomes Martins | RM555999 |
| Matheus de Mattos Vecchi | RM561716 |
| Nicholas Albuquerque Buzo | RM561082 |
| Nicholas Camillo Canadas de Paula | RM561262 |
| Pedro dos Anjos Viana Moraes | RM563832 |

---

> **FIAP** — Análise e Desenvolvimento de Sistemas  
> Disciplina: DevOps Tools & Cloud Computing  
> Parceiro: **CLYVO VET** | Repositório base: [github.com/gugomesx10/PetOS-Java](https://github.com/gugomesx10/PetOS-Java)
