$ErrorActionPreference = 'Stop' # Equivalente ao set -e

Write-Output "Configurando projeto Matis..."
Write-Output ""

# Verificar se estamos na raiz do projeto
if (-not (Test-Path "docker-compose.yml")) {
    Write-Error "Execute este script na raiz do projeto (onde está o docker-compose.yml)"
    exit 1
}

Write-Output "1. Verificando .env.example na raiz..."

# Verificar se .env.example existe na raiz
if (-not (Test-Path ".\.env.example")) {
    Write-Error "Arquivo .\.env.example não encontrado na raiz do projeto"
    exit 1
}

# Verificar se credential-generator.sh existe
if (-not (Test-Path ".\credential-generator.sh")) {
    Write-Error "Arquivo .\credential-generator.sh não encontrado"
    exit 1
}

Write-Output ""
Write-Output "2. Gerando credenciais e criando .env..."

# Copiar .env.example para .env na raiz
Copy-Item ".\.env.example" -Destination ".\.env" -Force
Write-Output "Arquivo .\.env criado na raiz"

# Executar gerador de credenciais (Requer Git Bash ou similar no PATH)
Write-Output "Gerando credenciais JWT..."
bash ./credential-generator.sh

Write-Output ""
Write-Output "3. Interpolando variáveis de ambiente..."

# Lógica equivalente a 'source .env' e 'envsubst'
$envContent = Get-Content ".\.env"

# 1. Carregar variáveis na memória
foreach ($line in $envContent) {
    if ($line -match "^\s*(?<key>[A-Z_]+)=(?<value>.*)$") {
        [Environment]::SetEnvironmentVariable($Matches.key, $Matches.value, "Process")
    }
}

# 2. Substituir ${VAR} pelos valores reais
$interpolatedContent = $envContent | ForEach-Object {
    [Regex]::Replace($_, '\$\{([A-Z_]+)\}', { 
        param($m) 
        [Environment]::GetEnvironmentVariable($m.Groups[1].Value, "Process") 
    })
}

$interpolatedContent | Set-Content ".\.env" -Encoding UTF8
Write-Output "Variáveis interpoladas com sucesso"

Write-Output ""
Write-Output "4. Separando variáveis de ambiente..."

# Backend: todas as variáveis exceto VITE_*
$interpolatedContent | Where-Object { $_ -notmatch "^VITE_" } | Set-Content ".\backend\.env" -Encoding UTF8
Write-Output "Arquivo .\backend\.env criado (sem VITE_*)"

# Frontend: apenas variáveis VITE_*
$interpolatedContent | Where-Object { $_ -match "^VITE_" } | Set-Content ".\frontend\.env" -Encoding UTF8
Write-Output "Arquivo .\frontend\.env criado (apenas VITE_*)"

Write-Output ""
Write-Output "Configuração concluída com sucesso!"
Write-Output ""
Write-Output "Próximos passos:"
Write-Output "   1. Execute: docker compose up --build"
Write-Output "   2. Em outro terminal: docker exec low-code-js-api npm run seed"
Write-Output ""
Write-Output "Acessos:"
Write-Output "   Frontend: http://localhost:5173"
Write-Output "   Backend:  http://localhost:3000"
Write-Output "   Docs:     http://localhost:3000/documentation"
Write-Output ""