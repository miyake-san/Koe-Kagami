# Koe-Kagami (声鏡)

**Koe-Kagami** — "Espelho de Vozes". Uma plataforma full-stack, orientada a IA, para simulação
multi-agente: agentes sintéticos (personas) debatem e reagem a produtos, campanhas e cenários,
e o resultado é um "espelho" das vozes/opiniões do mercado real.

## Arquitetura

```text
Koe-Kagami/
├── backend/                 # API Python 3.13 (FastAPI + TinyTroupe + Microsoft Agent Framework)
│   ├── agents/              # Definições de personas/agentes
│   ├── core/                # Configuração e serviços compartilhados
│   ├── simulations/         # Cenários de simulação
│   ├── main.py              # Entrypoint FastAPI
│   ├── pyproject.toml       # Projeto uv + ruff + taskipy
│   └── Dockerfile           # Imagem Python 3.13 baseada em uv
├── frontend/                # SPA React + TypeScript (Vite)
│   ├── src/
│   ├── nginx.conf
│   └── Dockerfile           # Build multi-stage, servido por nginx
├── infra/
│   ├── bicep/               # IaC Azure com Bicep
│   │   ├── main.bicep
│   │   ├── main.parameters.json
│   │   └── modules/container-apps.bicep
│   └── terraform/           # IaC Azure com Terraform
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── docker-compose.yml       # Stack local (frontend + backend)
├── .gitignore
└── README.md
```

### Componentes

| Camada | Tecnologia | Papel |
| --- | --- | --- |
| Frontend | React 19 + TypeScript + Vite | Console para configurar simulações e visualizar insights |
| Backend | FastAPI (Python 3.13) | Orquestra agentes e expõe a API REST |
| Agentes | TinyTroupe + Microsoft Agent Framework | Personas sintéticas e orquestração multi-agente |
| LLM | Azure OpenAI (SDK `openai` + `azure-identity`) | Motor de raciocínio dos agentes |
| Infra | Azure Container Apps, ACR, Azure OpenAI, Azure AI Foundry | Hospedagem e serviços de IA |

## Executando localmente

### Backend com `uv`

```bash
cd backend
uv sync                 # ou: uv run task setup
uv run task start       # uvicorn main:app --reload em http://localhost:8000
uv run task lint        # ruff check + ruff format --check
```

Endpoints iniciais: `GET /` e `GET /health`. Documentação interativa em `http://localhost:8000/docs`.

### Frontend com Vite

```bash
cd frontend
npm install
npm run dev             # http://localhost:5173
```

### Stack completa com Docker Compose

```bash
docker compose up --build
```

- Frontend: http://localhost:5173
- Backend: http://localhost:8000

Variáveis de ambiente úteis (podem ficar em um `.env` na raiz):

| Variável | Descrição |
| --- | --- |
| `AZURE_OPENAI_ENDPOINT` | Endpoint do recurso Azure OpenAI |
| `AZURE_OPENAI_DEPLOYMENT` | Nome do deployment do modelo (default `gpt-4o`) |
| `KOE_CORS_ORIGINS` | Origens permitidas pelo CORS, separadas por vírgula |

## Deploy no Azure

Ambas as opções provisionam: Azure Container Registry (ACR), ambiente e apps do Azure Container
Apps (ACA) para backend e frontend, Azure OpenAI (com deployment de modelo) e Azure AI Foundry
(hub + project, com Storage e Key Vault associados).

### Opção 1 — Bicep

```bash
az login
az group create --name koekagami-rg --location eastus2

az deployment group create \
  --resource-group koekagami-rg \
  --template-file infra/bicep/main.bicep \
  --parameters infra/bicep/main.parameters.json
```

Depois de criar o ACR, publique as imagens e reimplante apontando para elas:

```bash
ACR=$(az deployment group show -g koekagami-rg -n main --query properties.outputs.acrLoginServer.value -o tsv)
az acr login --name ${ACR%%.*}

docker build -t $ACR/koe-kagami-backend:latest ./backend
docker build -t $ACR/koe-kagami-frontend:latest ./frontend
docker push $ACR/koe-kagami-backend:latest
docker push $ACR/koe-kagami-frontend:latest

az deployment group create \
  --resource-group koekagami-rg \
  --template-file infra/bicep/main.bicep \
  --parameters infra/bicep/main.parameters.json \
    backendImage=$ACR/koe-kagami-backend:latest \
    frontendImage=$ACR/koe-kagami-frontend:latest
```

### Opção 2 — Terraform

```bash
az login
cd infra/terraform
terraform init
terraform plan
terraform apply
```

Para publicar suas próprias imagens, faça `terraform apply` uma primeira vez, envie as imagens ao
ACR criado (mesmos comandos `docker build`/`docker push` acima) e aplique novamente:

```bash
terraform apply \
  -var="backend_image=$(terraform output -raw acr_login_server)/koe-kagami-backend:latest" \
  -var="frontend_image=$(terraform output -raw acr_login_server)/koe-kagami-frontend:latest"
```

As URLs públicas ficam disponíveis nos outputs `backend_url` e `frontend_url` (Terraform) ou
`backendUrl`/`frontendUrl` (Bicep).

> Autenticação: os Container Apps usam **managed identity** para puxar imagens do ACR e acessar o
> Azure OpenAI (`Cognitive Services OpenAI User`), evitando chaves em texto plano.

## Licença

Distribuído sob os termos do arquivo [LICENSE](LICENSE).
