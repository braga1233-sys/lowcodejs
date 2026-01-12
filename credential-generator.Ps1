# Gera as chaves temporárias
& "C:\Program Files\Git\usr\bin\openssl.exe" genrsa -out temp_private.pem 2048
& "C:\Program Files\Git\usr\bin\openssl.exe" rsa -in temp_private.pem -pubout -out temp_public.pem

# Define as variáveis
$JWT_PRIVATE_KEY = [Convert]::ToBase64String([IO.File]::ReadAllBytes("temp_private.pem"))
$JWT_PUBLIC_KEY = [Convert]::ToBase64String([IO.File]::ReadAllBytes("temp_public.pem"))
$COOKIE_SECRET = -join ((1..64 | ForEach-Object { '{0:x}' -f (Get-Random -Maximum 16) }))

# Cria ou atualiza o arquivo .env
$ENV_FILE = ".env"

# Cria o arquivo .env se não existir
if (-Not (Test-Path $ENV_FILE)) {
    New-Item -ItemType File -Path $ENV_FILE | Out-Null
}

# Remove as chaves antigas se existirem
(Get-Content $ENV_FILE) | Where-Object { $_ -notmatch '^JWT_PRIVATE_KEY=' -and $_ -notmatch '^JWT_PUBLIC_KEY=' -and $_ -notmatch '^COOKIE_SECRET=' } | Set-Content $ENV_FILE

# Adiciona as novas chaves
Add-Content -Path $ENV_FILE -Value "JWT_PRIVATE_KEY=$JWT_PRIVATE_KEY"
Add-Content -Path $ENV_FILE -Value "JWT_PUBLIC_KEY=$JWT_PUBLIC_KEY"
Add-Content -Path $ENV_FILE -Value "COOKIE_SECRET=$COOKIE_SECRET"

# Remove os arquivos temporários
Remove-Item temp_private.pem, temp_public.pem

Write-Host "✅ Chaves geradas e adicionadas ao arquivo $ENV_FILE com sucesso!"