#!/bin/bash
# =========================================================
# PetOS — Script Azure CLI
# Tarefa 01: Provisionar VM Linux, abrir portas,
#            instalar Docker e ferramentas necessárias
# =========================================================
# PRÉ-REQUISITO : az login já executado e usuário logado
# USO           : chmod +x azure-setup.sh && ./azure-setup.sh
# =========================================================
# Variáveis de configuração
# =========================================================
RESOURCE_GROUP="rg-petos"
LOCATION="eastus"
VM_NAME="vm-petos"
VM_SIZE="Standard_B2s"
VM_IMAGE="Ubuntu2204"
ADMIN_USER="petosadmin"
NSG_NAME="nsg-petos"
PUBLIC_IP_NAME="pip-petos"

# =========================================================
# Criando Resource Group
# =========================================================

echo ">> Criando Resource Group: $RESOURCE_GROUP ..."

az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION
  --output table

echo "Resource Group criado."

# =========================================================
# Criando VM
# =========================================================

echo ">> Criando VM Linux Ubuntu 22.04 ($VM_SIZE)..."

az vm create \
  --resource-group $RESOURCE_GROUP \
  --name $VM_NAME \
  --image $VM_IMAGE \
  --size $VM_SIZE \
  --admin-username $ADMIN_USER \
  --authentication-type ssh \
  --generate-ssh-keys \
  --public-ip-sku Standard \
  --public-ip-address $PUBLIC_IP_NAME \
  --nsg $NSG_NAME \
  --output table

# Captura o IP público
VM_IP=$(az vm show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM_NAME" \
  --show-details \
  --query publicIps \
  --output tsv)

echo ""
echo "VM criada com sucesso!"
echo "IP Público: $VM_IP"

# =========================================================
# Abrindo portas no Network Security Group...
# =========================================================
echo ">> Abrindo portas necessárias..."

az network nsg rule create \
  --resource-group "$RESOURCE_GROUP" \
  --nsg-name "$NSG_NAME" \
  --name "Allow-SSH" \
  --protocol Tcp \
  --priority 100 \
  --destination-port-range 22 \
  --access Allow \
  --direction Inbound \
  --output table

az network nsg rule create \
  --resource-group "$RESOURCE_GROUP" \
  --nsg-name "$NSG_NAME" \
  --name "Allow-API-8080" \
  --protocol Tcp \
  --priority 200 \
  --destination-port-range 8080 \
  --access Allow \
  --direction Inbound \
  --output table

az network nsg rule create \
  --resource-group "$RESOURCE_GROUP" \
  --nsg-name "$NSG_NAME" \
  --name "Allow-HTTP-80" \
  --protocol Tcp \
  --priority 300 \
  --destination-port-range 80 \
  --access Allow \
  --direction Inbound \
  --output table


echo "Portas abertas: 22 (SSH) | 80 (HTTP) | 8080 (API + H2 Console)"

# =========================================================
# Instalando Docker e ferramentas necessárias
# =========================================================
echo ">> Instalando Docker e ferramentas necessárias na VM..."

az vm run-command invoke \
  --resource-group $RESOURCE_GROUP \
  --name $VM_NAME \
  --command-id RunShellScript \
  --scripts "

  	echo '>> Atualizando pacotes do sistema...'
  	sudo apt update -y
  	sudo apt upgrade -y

	echo '>> Instalando ferramentas'
	sudo apt install -y \
		git \
		nano \
		curl \
		unzip \
		wget \

	echo '>> Instalando Docker...'
	curl -fsSL https://get.docker.com | sudo sh
	systemctl enable docker
	systemctl start docker
    sudo usermod -aG docker $ADMIN_USER
    	sudo apt install -y \
    	docker-compose-plugin \
    	docker-ce \
        docker-ce-cli \
        docker-buildx-plugin
  mkdir -p /opt/petos

	echo ''
	echo 'Instalação concluída com sucesso!'
  " \
  --output table

# =========================================================
# Próximos passos
# =========================================================
echo ""	
echo "══════════════════════════════════════════"
echo "      Infraestrutura provisionada!        "
echo "══════════════════════════════════════════"
echo ""
echo "Resource Group : $RESOURCE_GROUP"
echo "VM             : $VM_NAME"
echo "IP Público     : $VM_IP"
echo "SO             : Ubuntu 22.04 LTS"
echo "Tamanho        : $VM_SIZE"
echo "Portas abertas : 22 | 80 | 8080"

echo ""
echo "Conecte usando:"
echo "ssh $ADMIN_USER@$VM_IP"

echo ""
echo "Após entrar na VM:"
echo "docker --version"
echo "docker compose version"

echo ""
echo "Tudo pronto para subir os containers."
echo "Seguir com a clonagem do projeto:"
echo "cd /opt/petos"
echo "git clone https://github.com/nicholasbuzo/Cloud-PetOS.git"

echo ""
echo "Subir container em background:"
echo "docker compose up -d --build"

echo ""
echo "Verificar status:"
echo "docker compose ps"
echo "docker compose logs -f"

echo ""
echo "Testar externamente (do seu computador):"
echo "curl http://$VM_IP:8080/actuator/health"
echo "curl http://$VM_IP:8080/pets"

echo ""
echo "H2 Console:"
echo "http://$VM_IP:8080/h2-console"
echo "JDBC URL: jdbc:h2:file:/app/data/petosdb"
echo "Usuário : sa  |  Senha: (vazio)"

echo ""
echo "Swagger UI:"
echo "http://$VM_IP:8080/swagger-ui.html"
echo ""
