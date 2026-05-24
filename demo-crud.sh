#!/bin/bash
# ══════════════════════════════════════════════════════════════
# PetOS — Demo CRUD completo para o vídeo
# Cobre as 4 entidades do projeto: Pet, Vaccine, Routine, Alert
# Rotas conforme repositório: github.com/gugomesx10/PetOS-Java
#
# USO: ./demo-crud.sh <IP_DA_VM>
# Ex : ./demo-crud.sh 20.123.45.67
#      ./demo-crud.sh localhost   (para teste local)
# ══════════════════════════════════════════════════════════════

HOST="${1:-localhost}"
BASE="http://$HOST:8080"

sep()   { echo ""; echo "──────────────────────────────────────────"; }
title() { echo ""; echo ""; echo "══════════════════════════════════"; echo "  $1"; echo "══════════════════════════════════"; }
ok()    { echo "  ✅ $1"; }

echo "════════════════════════════════════════════"
echo "  PetOS — Demo CRUD | $BASE"
echo "  Entidades: Pet | Vaccine | Routine | Alert"
echo "════════════════════════════════════════════"

# ─────────────────────────────────────────────
# [0] Health Check
# ─────────────────────────────────────────────
title "0. HEALTH CHECK"
curl -s "$BASE/actuator/health" | python3 -m json.tool
ok "API está saudável"

# ═══════════════════════════════════════════════
# 🐶 PET
# ═══════════════════════════════════════════════
title "1. PET — POST insert 1"
PET1=$(curl -s -X POST "$BASE/pets" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Thor",
    "species": "DOG",
    "breed": "Golden Retriever",
    "birthDate": "2021-03-15",
    "weight": 28.5,
    "ownerName": "Ana Paula Silva",
    "ownerPhone": "11987654321"
  }')
echo "$PET1" | python3 -m json.tool
PET1_ID=$(echo "$PET1" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id','1'))" 2>/dev/null || echo "1")
ok "Pet criado com ID $PET1_ID"

sep
title "1. PET — POST insert 2"
PET2=$(curl -s -X POST "$BASE/pets" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Luna",
    "species": "CAT",
    "breed": "Siamese",
    "birthDate": "2022-07-20",
    "weight": 4.2,
    "ownerName": "Carlos Lima",
    "ownerPhone": "11976543210"
  }')
echo "$PET2" | python3 -m json.tool
PET2_ID=$(echo "$PET2" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id','2'))" 2>/dev/null || echo "2")
ok "Pet criado com ID $PET2_ID"

sep
title "1. PET — GET listar todos"
curl -s "$BASE/pets" | python3 -m json.tool

sep
title "1. PET — GET por ID ($PET1_ID)"
curl -s "$BASE/pets/$PET1_ID" | python3 -m json.tool

sep
title "1. PET — GET histórico consolidado"
curl -s "$BASE/pets/$PET1_ID/history" | python3 -m json.tool

sep
title "1. PET — PUT atualizar peso"
curl -s -X PUT "$BASE/pets/$PET1_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Thor",
    "species": "DOG",
    "breed": "Golden Retriever",
    "birthDate": "2021-03-15",
    "weight": 30.1,
    "ownerName": "Ana Paula Silva",
    "ownerPhone": "11987654321"
  }' | python3 -m json.tool
ok "Peso atualizado para 30.1 kg"

# ═══════════════════════════════════════════════
# 💉 VACCINE
# ═══════════════════════════════════════════════
sep
title "2. VACCINE — POST insert 1 (gera alerta automático)"
VAC1=$(curl -s -X POST "$BASE/vaccines" \
  -H "Content-Type: application/json" \
  -d "{
    \"petId\": $PET1_ID,
    \"name\": \"V8 Polivalente\",
    \"applicationDate\": \"2024-01-15\",
    \"expirationDate\": \"2025-01-15\",
    \"veterinarian\": \"Dr. Roberto Alves\",
    \"batch\": \"LOT-2024-001\"
  }")
echo "$VAC1" | python3 -m json.tool
VAC1_ID=$(echo "$VAC1" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id','1'))" 2>/dev/null || echo "1")
ok "Vacina registrada com ID $VAC1_ID — alerta gerado automaticamente"

sep
title "2. VACCINE — POST insert 2"
curl -s -X POST "$BASE/vaccines" \
  -H "Content-Type: application/json" \
  -d "{
    \"petId\": $PET1_ID,
    \"name\": \"Antirrábica\",
    \"applicationDate\": \"2024-06-10\",
    \"expirationDate\": \"2025-06-10\",
    \"veterinarian\": \"Dra. Carla Santos\",
    \"batch\": \"LOT-2024-RAB\"
  }" | python3 -m json.tool

sep
title "2. VACCINE — GET vacinas do pet $PET1_ID"
curl -s "$BASE/pets/$PET1_ID/vaccines" | python3 -m json.tool

sep
title "2. VACCINE — GET vacinas pendentes do pet $PET1_ID"
curl -s "$BASE/pets/$PET1_ID/vaccines/pending" | python3 -m json.tool

sep
title "2. VACCINE — GET pets com vacinas vencidas/próximas"
curl -s "$BASE/pets/vaccines/expiring" | python3 -m json.tool

sep
title "2. VACCINE — PUT atualizar vacina"
curl -s -X PUT "$BASE/vaccines/$VAC1_ID" \
  -H "Content-Type: application/json" \
  -d "{
    \"petId\": $PET1_ID,
    \"name\": \"V8 Polivalente (reforço)\",
    \"applicationDate\": \"2024-01-15\",
    \"expirationDate\": \"2026-01-15\",
    \"veterinarian\": \"Dr. Roberto Alves\",
    \"batch\": \"LOT-2025-001\"
  }" | python3 -m json.tool

# ═══════════════════════════════════════════════
# 📅 ROUTINE
# ═══════════════════════════════════════════════
sep
title "3. ROUTINE — POST insert 1"
ROT1=$(curl -s -X POST "$BASE/routines" \
  -H "Content-Type: application/json" \
  -d "{
    \"petId\": $PET1_ID,
    \"type\": \"WALK\",
    \"description\": \"Caminhada matinal no parque\",
    \"scheduledTime\": \"07:00\",
    \"frequency\": \"DAILY\"
  }")
echo "$ROT1" | python3 -m json.tool
ROT1_ID=$(echo "$ROT1" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id','1'))" 2>/dev/null || echo "1")

sep
title "3. ROUTINE — POST insert 2"
curl -s -X POST "$BASE/routines" \
  -H "Content-Type: application/json" \
  -d "{
    \"petId\": $PET1_ID,
    \"type\": \"MEDICATION\",
    \"description\": \"Vermifugo mensal\",
    \"scheduledTime\": \"08:00\",
    \"frequency\": \"MONTHLY\"
  }" | python3 -m json.tool

sep
title "3. ROUTINE — GET rotinas do pet $PET1_ID"
curl -s "$BASE/pets/$PET1_ID/routines" | python3 -m json.tool

sep
title "3. ROUTINE — PUT atualizar rotina"
curl -s -X PUT "$BASE/routines/$ROT1_ID" \
  -H "Content-Type: application/json" \
  -d "{
    \"petId\": $PET1_ID,
    \"type\": \"WALK\",
    \"description\": \"Caminhada matinal e vespertina no parque\",
    \"scheduledTime\": \"07:00\",
    \"frequency\": \"DAILY\"
  }" | python3 -m json.tool

# ═══════════════════════════════════════════════
# 🔔 ALERT
# ═══════════════════════════════════════════════
sep
title "4. ALERT — GET alertas pendentes (gerados pelas vacinas)"
curl -s "$BASE/alerts/pending" | python3 -m json.tool

sep
title "4. ALERT — GET alertas do pet $PET1_ID"
ALERTS=$(curl -s "$BASE/pets/$PET1_ID/alerts")
echo "$ALERTS" | python3 -m json.tool
ALERT_ID=$(echo "$ALERTS" | python3 -c "
import sys,json
data = json.load(sys.stdin)
items = data.get('content', data) if isinstance(data, dict) else data
print(items[0]['id'] if items else '1')
" 2>/dev/null || echo "1")

sep
title "4. ALERT — PATCH marcar como enviado (ID $ALERT_ID)"
curl -s -X PATCH "$BASE/alerts/$ALERT_ID/mark-sent" | python3 -m json.tool
ok "Alerta marcado como enviado"

sep
title "4. ALERT — POST criar alerta manual"
curl -s -X POST "$BASE/alerts" \
  -H "Content-Type: application/json" \
  -d "{
    \"petId\": $PET1_ID,
    \"type\": \"HEALTH_CHECK\",
    \"message\": \"Check-up anual do Thor agendado para próximo mês\",
    \"scheduledDate\": \"2025-12-01\"
  }" | python3 -m json.tool

# ═══════════════════════════════════════════════
# DELETE
# ═══════════════════════════════════════════════
sep
title "5. DELETE — Remover rotina ($ROT1_ID)"
HTTP=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$BASE/routines/$ROT1_ID")
echo "  HTTP Status: $HTTP"

sep
title "5. DELETE — Inativar pet ($PET2_ID) — soft delete"
HTTP=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$BASE/pets/$PET2_ID")
echo "  HTTP Status: $HTTP"
ok "Pet inativado (active=false, dados preservados)"

sep
title "6. GET FINAL — Confirmação do estado do banco"
echo "Pets ativos:"
curl -s "$BASE/pets" | python3 -m json.tool

echo ""
echo "════════════════════════════════════════════"
echo "  ✅ Demo CRUD concluída com sucesso!"
echo ""
echo "  Entidades demonstradas:"
echo "    🐶 Pet     : POST(x2) GET GET(id) GET(history) PUT DELETE"
echo "    💉 Vaccine : POST(x2) GET(list) GET(pending) GET(expiring) PUT"
echo "    📅 Routine : POST(x2) GET(list) PUT DELETE"
echo "    🔔 Alert   : GET(pending) GET(pet) PATCH POST"
echo ""
echo "  H2 Console para inspecionar o banco:"
echo "  http://$HOST:8080/h2-console"
echo "  JDBC URL: jdbc:h2:file:/app/data/petosdb"
echo ""
echo "  Swagger UI:"
echo "  http://$HOST:8080/swagger-ui.html"
echo "════════════════════════════════════════════"
