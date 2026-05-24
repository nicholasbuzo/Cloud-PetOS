#!/bin/bash
# ══════════════════════════════════════════════════════════════
# PetOS — DELETAR todos os recursos Azure
# ══════════════════════════════════════════════════════════════

RESOURCE_GROUP="rg-petos"

echo "════════════════════════════════════════════"
echo "  PetOS — Remoção da Infraestrutura Azure"
echo "════════════════════════════════════════════"
echo ""
echo "  Esta ação irá DELETAR permanentemente:"
echo "  Resource Group : $RESOURCE_GROUP"
echo "  VM             : vm-petos"
echo "  NSG, IP público, disco e VNet"
echo ""
read -p "  Digite 'sim' para confirmar: " CONFIRM

if [ "$CONFIRM" != "sim" ]; then
  echo "  Operação cancelada."
  exit 0
fi

echo ""
echo "Deletando Resource Group '$RESOURCE_GROUP'..."

az group delete \
  --name "$RESOURCE_GROUP" \
  --yes \
  --no-wait

echo ""
echo "  Comando de deleção enviado!"
echo "  A remoção completa leva alguns minutos."
echo ""
echo "  Para confirmar remoção:"
echo "  az group show --name $RESOURCE_GROUP"
echo ""
echo "  Para listar grupos restantes:"
echo "  az group list --output table"
echo ""
