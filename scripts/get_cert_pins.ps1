# Script to extract certificate pins from Supabase domain
# Run: powershell -File scripts\get_cert_pins.ps1

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$domain = 'njjurkgagfypwjqnsqfc.supabase.co'
$port = 443

# Get certificate chain
$tcpClient = New-Object System.Net.Sockets.TcpClient
$tcpClient.Connect($domain, $port)

$sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream(), $false)
$sslStream.AuthenticateAsClient($domain)

$cert = $sslStream.RemoteCertificate
$certChain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
$certChain.Build($cert)

Write-Host "Certificate Chain for $domain ($port)" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

foreach ($chainElement in $certChain.ChainElements) {
    $cert = $chainElement.Certificate
    
    # Get public key and calculate SHA-256
    $pubKey = $cert.PublicKey.EncodedKeyValue.RawData
    $sha256 = New-Object System.Security.Cryptography.SHA256CryptoServiceProvider
    $publicKeySHA256 = $sha256.ComputeHash($pubKey)
    $pin = [Convert]::ToBase64String($publicKeySHA256)
    
    Write-Host ""
    Write-Host "Subject: $($cert.Subject)" -ForegroundColor Cyan
    Write-Host "Issuer: $($cert.Issuer)" -ForegroundColor Cyan
    Write-Host "Valid From: $($cert.NotBefore)" -ForegroundColor Yellow
    Write-Host "Valid Until: $($cert.NotAfter)" -ForegroundColor Yellow
    Write-Host "Thumbprint (SHA1): $($cert.Thumbprint)" -ForegroundColor Magenta
    Write-Host "PIN (SHA-256 of public key):" -ForegroundColor Green
    Write-Host $pin -ForegroundColor White
}

$sslStream.Close()
$tcpClient.Close()
