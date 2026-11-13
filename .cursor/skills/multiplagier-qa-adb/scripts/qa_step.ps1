# QA ADB por etapa — Multiplagier Mobile (sem SEC-003).
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("setup", "login", "conta", "carrinho", "pagamento", "logout")]
  [string]$Step
)

$ErrorActionPreference = "Continue"
$env:Path = "C:\Android\Sdk\platform-tools;" + $env:Path
$shotDir = Join-Path $env:USERPROFILE "Desktop\multiplagier-e2e-mcp"
New-Item -ItemType Directory -Force -Path $shotDir | Out-Null
$pkg = "br.edu.fatec.multiplagier.multiplagier_mobile"
$email = "cliente@multiplagier.local"
$pass = "Multiplagier@2026"

function Dump-Ui {
  adb shell uiautomator dump /sdcard/ui.xml 2>$null | Out-Null
  adb pull /sdcard/ui.xml "$env:TEMP\ui.xml" 2>$null | Out-Null
  if (-not (Test-Path "$env:TEMP\ui.xml")) { return "" }
  Get-Content "$env:TEMP\ui.xml" -Raw
}
function Descs {
  [regex]::Matches((Dump-Ui), 'content-desc="([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
}
function Shot([string]$name) {
  $path = Join-Path $shotDir "$name.png"
  adb exec-out screencap -p > $path
  Write-Host "SHOT=$path"
}
function Nodes {
  $xml = Dump-Ui
  if (-not $xml) { return @() }
  [regex]::Matches(
    $xml,
    'content-desc="([^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"'
  ) | ForEach-Object {
    [pscustomobject]@{
      Desc = $_.Groups[1].Value
      T = [int]$_.Groups[3].Value
      X = [int](([int]$_.Groups[2].Value + [int]$_.Groups[4].Value) / 2)
      Y = [int](([int]$_.Groups[3].Value + [int]$_.Groups[5].Value) / 2)
      H = [int]$_.Groups[5].Value - [int]$_.Groups[3].Value
      W = [int]$_.Groups[4].Value - [int]$_.Groups[2].Value
    }
  }
}
function Tap([int]$x, [int]$y) {
  adb shell input tap $x $y | Out-Null
  Start-Sleep -Milliseconds 200
}
function Tap-Desc([string]$needle) {
  $n = Nodes | Where-Object { $_.Desc -like "*$needle*" } | Select-Object -First 1
  if (-not $n) { Write-Host "MISS:$needle"; return $false }
  Tap $n.X $n.Y
  return $true
}
function Wait-Desc([string]$needle, [int]$tries = 25) {
  for ($i = 0; $i -lt $tries; $i++) {
    if ((Descs) | Where-Object { $_ -like "*$needle*" } | Select-Object -First 1) { return $true }
    Start-Sleep -Milliseconds 300
  }
  return $false
}
function Adb-Type([string]$text) {
  $escaped = $text.Replace("\", "\\").Replace(" ", "%s").Replace("@", "\@").Replace("&", "\&").Replace("<", "\<").Replace(">", "\>")
  cmd /c "adb shell input text $escaped" | Out-Null
  Start-Sleep -Milliseconds 100
}
function Clear-Focused {
  adb shell input keycombination 113 29 2>$null | Out-Null
  Start-Sleep -Milliseconds 40
  adb shell input keyevent 67 | Out-Null
}
function Back {
  adb shell input keyevent 4 | Out-Null
  Start-Sleep -Milliseconds 250
}
function Ensure-Foreground {
  adb shell am start -W -n "$pkg/.MainActivity" | Out-Null
  Start-Sleep -Milliseconds 400
}
function Fill-Login {
  Ensure-Foreground
  if (-not (Wait-Desc "Entrar" 20)) {
    adb shell input keyevent 3 | Out-Null
    Start-Sleep -Milliseconds 200
    adb shell am force-stop $pkg | Out-Null
    adb shell am start -W -n "$pkg/.MainActivity" | Out-Null
    if (-not (Wait-Desc "Entrar" 30)) { return $false }
  }
  Tap 540 1128
  Clear-Focused
  Adb-Type $email
  adb shell input keyevent 111 | Out-Null
  Start-Sleep -Milliseconds 150
  Tap 540 1306
  Clear-Focused
  Adb-Type $pass
  adb shell input keyevent 111 | Out-Null
  Start-Sleep -Milliseconds 150
  $entrar = Nodes | Where-Object { $_.Desc -eq "Entrar" -and $_.H -lt 160 -and $_.T -gt 1300 } | Select-Object -First 1
  if ($entrar) { Tap $entrar.X $entrar.Y } else { Tap 540 1501 }
  return (Wait-Desc "Carrinho" 20) -or (Wait-Desc "Minha conta" 10)
}
function Fail([string]$msg) {
  Write-Host "FAIL:$msg"
  exit 1
}
function Ok([string]$msg) {
  Write-Host "OK:$msg"
  exit 0
}

Write-Host "=== STEP $Step ==="

switch ($Step) {
  "setup" {
    $dev = adb devices | Select-String "emulator-\d+\s+device"
    if (-not $dev) { Fail "emulador offline" }
    Ensure-Foreground
    if (-not (Wait-Desc "Entrar" 25)) {
      # já logado? ainda assim setup ok se app focado
      $focus = adb shell dumpsys window | Select-String "multiplagier_mobile"
      if (-not $focus) { Fail "app sem foco / sem tela Entrar" }
    }
    Shot "00-setup"
    Ok "setup"
  }
  "login" {
    if (-not (Fill-Login)) {
      Shot "01-login-fail"
      Fail "login"
    }
    Shot "01-catalogo"
    Ok "login"
  }
  "conta" {
    Ensure-Foreground
    if (-not (Tap-Desc "Minha conta")) { Fail "botao Minha conta" }
    Start-Sleep -Milliseconds 450
    $d = (Descs) -join " | "
    if ($d -notmatch "Salvar|Sair") {
      Shot "02-conta-fail"
      Fail "tela conta"
    }
    Shot "02-conta"
    Ok "conta"
  }
  "carrinho" {
    Ensure-Foreground
    [void](Tap-Desc "udio")
    Start-Sleep -Milliseconds 300
    if (-not (Tap-Desc "Fone")) { Fail "produto Fone" }
    Start-Sleep -Milliseconds 400
    if (-not (Tap-Desc "Adicionar")) { Fail "Adicionar" }
    Start-Sleep -Milliseconds 400
    Back
    Start-Sleep -Milliseconds 200
    # Com badge, o content-desc vira o número ("1") em vez de "Carrinho".
    if (-not (Tap-Desc "Carrinho")) {
      $badge = Nodes | Where-Object { $_.Desc -match '^\d+$' -and $_.T -lt 200 } | Select-Object -First 1
      if ($badge) { Tap $badge.X $badge.Y }
      else { Fail "Carrinho" }
    }
    Start-Sleep -Milliseconds 450
    $d = (Descs) -join " | "
    if ($d -notmatch "Finalizar|Total|Fone|R\$") {
      Shot "03-carrinho-fail"
      Fail "carrinho vazio/inesperado"
    }
    Shot "03-carrinho"
    Ok "carrinho"
  }
  "pagamento" {
    Ensure-Foreground
    if (-not (Tap-Desc "Finalizar")) {
      # pode estar no catálogo; tenta abrir carrinho
      [void](Tap-Desc "Carrinho")
      Start-Sleep -Milliseconds 400
      if (-not (Tap-Desc "Finalizar")) { Fail "Finalizar" }
    }
    Start-Sleep -Milliseconds 600
    $d = (Descs) -join " | "
    if ($d -notmatch "Pagamento|Entregar|Pix|Pagar|Confirmar|CEP|Mau|Flores") {
      Shot "04-pagamento-fail"
      Fail "tela pagamento"
    }
    Shot "04-pagamento"
    [void](Tap-Desc "Pix")
    Start-Sleep -Milliseconds 200
    if (-not (Tap-Desc "Confirmar")) { [void](Tap-Desc "Pagar") }
    if (-not ((Wait-Desc "Pendente" 15) -or ((Descs) -join " ") -match "Pedido|Entrega")) {
      Shot "05-pedido-fail"
      Fail "pedido"
    }
    Shot "05-pedido"
    Ok "pagamento"
  }
  "logout" {
    Ensure-Foreground
    # volta ao home se estiver em detalhe
    if (-not (Tap-Desc "Pedidos")) {
      Back
      Start-Sleep -Milliseconds 200
      [void](Tap-Desc "Pedidos")
    }
    Start-Sleep -Milliseconds 400
    Shot "06-pedidos"
    Back
    Start-Sleep -Milliseconds 200
    if (-not (Tap-Desc "Minha conta")) { Fail "Minha conta" }
    Start-Sleep -Milliseconds 350
    if (-not (Tap-Desc "Sair")) { Fail "Sair" }
    if (-not (Wait-Desc "Entrar" 15)) {
      Shot "07-logout-fail"
      Fail "logout"
    }
    Shot "07-login"
    Ok "logout"
  }
}
