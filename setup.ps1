<#
  AI 개발환경 원클릭 설치 스크립트 (Windows)
  비개발자를 위한 올인원 셋업

  설치 항목:
    Git · Node.js · Bun · Windows Terminal
    GitHub CLI · Claude Code · OpenCode · oh-my-opencode · 필수 플러그인

  사용법:
    irm https://raw.githubusercontent.com/hyungwoon/ai-dev-setup/main/setup.ps1 | iex
#>

$script:stepNum = 0

function Write-Header {
  Clear-Host
  Write-Host ""
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
  Write-Host "  AI 개발환경 원클릭 설치 (Windows)" -ForegroundColor White
  Write-Host "     Windows Terminal · Claude Code · OpenCode · oh-my-opencode" -ForegroundColor DarkGray
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
  Write-Host ""
}

function Write-Step($msg) {
  $script:stepNum++
  Write-Host ""
  Write-Host "[$($script:stepNum)] " -NoNewline -ForegroundColor Blue
  Write-Host $msg -ForegroundColor White
  Write-Host "──────────────────────────────────────" -ForegroundColor DarkGray
}

function Write-Ok($msg)   { Write-Host "  ✓ $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  ⚠ $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "  ✗ $msg" -ForegroundColor Red }
function Write-Skip($msg) { Write-Host "  → 이미 설치됨: $msg" -ForegroundColor DarkGray }
function Write-Info($msg) { Write-Host "  ℹ $msg" -ForegroundColor Cyan }

function Test-Cmd($name) { return [bool](Get-Command $name -ErrorAction SilentlyContinue) }

function Refresh-Path {
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function Read-YesNo {
  param([string]$Prompt, [string]$Default = "n")
  $hint = if ($Default -eq "y") { "[Y/n]" } else { "[y/N]" }
  $answer = Read-Host "  $Prompt $hint"
  if ([string]::IsNullOrWhiteSpace($answer)) { $answer = $Default }
  return $answer -match '^[Yy]'
}

function Read-Choice {
  param([string]$Prompt, [string[]]$Options)
  Write-Host "  $Prompt" -ForegroundColor White
  for ($i = 0; $i -lt $Options.Count; $i++) {
    Write-Host "    " -NoNewline
    Write-Host "$($i+1)" -NoNewline -ForegroundColor Cyan
    Write-Host ") $($Options[$i])"
  }
  return Read-Host "  번호를 선택하세요"
}

function Install-WingetCheck {
  Write-Step "winget 확인 (Windows 패키지 관리자)"
  if (Test-Cmd "winget") {
    Write-Skip "winget"
    return
  }
  Write-Warn "winget이 설치되어 있지 않습니다."
  Write-Info "Microsoft Store에서 '앱 설치 관리자'를 설치하세요."
  Write-Info "https://aka.ms/getwinget"
  Read-Host "  설치 후 Enter를 눌러주세요"
  Refresh-Path
  if (-not (Test-Cmd "winget")) {
    Write-Err "winget을 찾을 수 없습니다."
    exit 1
  }
}

function Install-Git {
  Write-Step "Git (버전 관리)"
  if (Test-Cmd "git") {
    Write-Skip "Git"
  } else {
    winget install Git.Git --accept-source-agreements --accept-package-agreements -e
    Refresh-Path
    if (Test-Cmd "git") { Write-Ok "Git 설치 완료" } else { Write-Err "Git 설치 실패" }
  }
}

function Install-Node {
  Write-Step "Node.js (JavaScript 런타임)"
  if (Test-Cmd "node") {
    Write-Skip "Node.js $(node --version)"
  } else {
    winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements -e
    Refresh-Path
    if (Test-Cmd "node") { Write-Ok "Node.js 설치 완료" } else { Write-Err "Node.js 설치 실패" }
  }
}

function Install-Bun {
  Write-Step "Bun (빠른 JavaScript 런타임)"
  if (Test-Cmd "bun") {
    Write-Skip "Bun $(bun --version)"
  } else {
    Write-Info "Bun을 설치합니다..."
    npm install -g bun 2>$null
    Refresh-Path
    if (Test-Cmd "bun") { Write-Ok "Bun 설치 완료" } else { Write-Warn "Bun 설치 실패 — npx fallback을 사용합니다." }
  }
}

function Install-WindowsTerminal {
  Write-Step "Windows Terminal"
  $installed = (Get-AppxPackage Microsoft.WindowsTerminal -ErrorAction SilentlyContinue) -or (Test-Cmd "wt")
  if ($installed) {
    Write-Skip "Windows Terminal"
  } else {
    winget install Microsoft.WindowsTerminal --accept-source-agreements --accept-package-agreements -e
    Write-Ok "설치 완료"
  }
}

function Install-GitHubCLI {
  Write-Step "GitHub CLI"
  if (Test-Cmd "gh") {
    Write-Skip "GitHub CLI"
  } else {
    winget install GitHub.cli --accept-source-agreements --accept-package-agreements -e
    Refresh-Path
    if (Test-Cmd "gh") { Write-Ok "GitHub CLI 설치 완료" } else { Write-Err "GitHub CLI 설치 실패" }
  }
  $authOk = $false
  try { $null = gh auth status 2>&1; $authOk = ($LASTEXITCODE -eq 0) } catch {}
  if (-not $authOk) {
    Write-Info "GitHub 로그인이 필요합니다."
    if (Read-YesNo "지금 GitHub에 로그인하시겠습니까?" "y") {
      gh auth login
    } else {
      Write-Warn "나중에 'gh auth login' 으로 로그인하세요."
    }
  }
}

function Install-ClaudeCode {
  Write-Step "Claude Code (Anthropic CLI)"
  if (Test-Cmd "claude") {
    Write-Skip "Claude Code"
  } else {
    Write-Info "Claude Code를 설치합니다..."
    npm install -g @anthropic-ai/claude-code
    Refresh-Path
    if (Test-Cmd "claude") { Write-Ok "설치 완료" } else { Write-Warn "터미널 재시작 후 'claude' 명령어를 확인하세요." }
  }
}

function Install-OpenCode {
  Write-Step "OpenCode (AI 코딩 에이전트)"
  if (Test-Cmd "opencode") {
    Write-Skip "OpenCode"
  } else {
    Write-Info "OpenCode를 설치합니다..."
    npm install -g opencode-ai
    Refresh-Path
    if (Test-Cmd "opencode") { Write-Ok "설치 완료" } else { Write-Err "설치 실패 — https://opencode.ai/docs 참조" }
  }
}

function Install-Omo {
  Write-Step "oh-my-opencode (OpenCode 플러그인)"
  Write-Host ""
  Write-Host "  ━━━ AI 서비스 구독 정보 확인 ━━━" -ForegroundColor Magenta
  Write-Host "  현재 사용 중인 서비스를 선택해주세요." -ForegroundColor DarkGray
  Write-Host ""

  $claudeFlag = "no"
  $cc = Read-Choice "Claude (Anthropic) 구독이 있나요?" @("없음", "Claude Pro / Max 구독 있음", "Claude Max (max20 = 20배 모드) 사용 중")
  switch ($cc) {
    "2" { $claudeFlag = "yes" }
    "3" { $claudeFlag = "max20" }
    default {
      $claudeFlag = "no"
      Write-Host ""
      Write-Warn "Claude 구독 없이는 Sisyphus 에이전트가 최적으로 작동하지 않을 수 있습니다."
    }
  }

  $openaiFlag = "no"
  Write-Host ""
  if (Read-YesNo "ChatGPT Plus / OpenAI 구독이 있나요?") { $openaiFlag = "yes" }

  $geminiFlag = "no"
  Write-Host ""
  if (Read-YesNo "Google Gemini를 사용하나요?") { $geminiFlag = "yes" }

  $copilotFlag = "no"
  Write-Host ""
  if (Read-YesNo "GitHub Copilot 구독이 있나요?") { $copilotFlag = "yes" }

  $zenFlag = "no"
  Write-Host ""
  if (Read-YesNo "OpenCode Zen을 사용하나요?") { $zenFlag = "yes" }

  $zaiFlag = "no"
  Write-Host ""
  if (Read-YesNo "Z.ai Coding Plan을 사용하나요?") { $zaiFlag = "yes" }

  $goFlag = "no"
  Write-Host ""
  if (Read-YesNo "OpenCode Go를 사용하나요?" ) { $goFlag = "yes" }

  Write-Host ""
  $runner = if (Test-Cmd "bunx") { "bunx" } else { "npx" }
  $cmd = "$runner oh-my-opencode install --no-tui --claude=$claudeFlag --openai=$openaiFlag --gemini=$geminiFlag --copilot=$copilotFlag --opencode-zen=$zenFlag --zai-coding-plan=$zaiFlag --opencode-go=$goFlag"
  Write-Info "실행: $cmd"
  Write-Host ""
  Invoke-Expression $cmd
  Write-Host ""
  Write-Ok "oh-my-opencode 설치 완료"
}

function Install-Plugins {
  Write-Step "필수 플러그인 설치"
  Write-Host ""
  Write-Host "  OpenCode 경험을 향상시키는 핵심 플러그인을 추가합니다." -ForegroundColor DarkGray
  Write-Host ""

  $configDir = Join-Path $env:USERPROFILE ".config\opencode"
  $configFile = Join-Path $configDir "opencode.json"

  if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir -Force | Out-Null }

  $config = @{}
  if (Test-Path $configFile) {
    try { $config = Get-Content $configFile -Raw | ConvertFrom-Json -AsHashtable } catch { $config = @{} }
  }

  if (-not $config.ContainsKey('$schema')) { $config['$schema'] = "https://opencode.ai/config.json" }
  if (-not $config.ContainsKey('plugin')) { $config['plugin'] = @() }

  $plugins = @(
    "opencode-notificator",
    "opencode-dynamic-context-pruning",
    "opencode-supermemory",
    "opencode-worktree",
    "opencode-vibeguard"
  )

  foreach ($p in $plugins) {
    if ($config['plugin'] -notcontains $p) { $config['plugin'] += $p }
  }

  $config | ConvertTo-Json -Depth 10 | Set-Content $configFile -Encoding UTF8

  Write-Ok "opencode-notificator             — 작업 완료 데스크톱 알림"
  Write-Ok "opencode-dynamic-context-pruning — 토큰 자동 절약"
  Write-Ok "opencode-supermemory             — 세션 간 기억 유지"
  Write-Ok "opencode-worktree                — Git worktree 자동화"
  Write-Ok "opencode-vibeguard               — 비밀 정보 자동 보호"
  Write-Host ""
  Write-Info "다음 opencode 실행 시 자동으로 설치됩니다."
}

function Write-DoneMsg {
  Write-Host ""
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
  Write-Host "  ✅ 모든 설치가 완료되었습니다!" -ForegroundColor White
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
  Write-Host ""

  Write-Host "  설치 결과:" -ForegroundColor White
  if (Test-Cmd "git")      { Write-Host "    ✓ Git" -ForegroundColor Green }
  if (Test-Cmd "node")     { Write-Host "    ✓ Node.js" -ForegroundColor Green }
  if (Test-Cmd "bun")      { Write-Host "    ✓ Bun" -ForegroundColor Green }
  if (Test-Cmd "gh")       { Write-Host "    ✓ GitHub CLI" -ForegroundColor Green }
  if (Test-Cmd "claude")   { Write-Host "    ✓ Claude Code" -ForegroundColor Green }
  if (Test-Cmd "opencode") { Write-Host "    ✓ OpenCode" -ForegroundColor Green }
  Write-Host "    ✓ oh-my-opencode" -ForegroundColor Green
  Write-Host "    ✓ 필수 플러그인 5개" -ForegroundColor Green

  Write-Host ""
  Write-Host "  다음 단계:" -ForegroundColor White
  Write-Host ""
  Write-Host "    1. " -NoNewline -ForegroundColor Cyan
  Write-Host "AI 서비스 로그인:"
  Write-Host "       opencode auth login" -ForegroundColor Cyan
  Write-Host "       claude" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "    2. " -NoNewline -ForegroundColor Cyan
  Write-Host "아무 프로젝트 폴더에서 시작:"
  Write-Host "       cd ~\my-project; opencode" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "  ──────────────────────────────────────" -ForegroundColor DarkGray
  Write-Host "  💡 팁: 프롬프트에 'ultrawork'를 포함하면 자동으로 끝까지 작업합니다." -ForegroundColor DarkGray
  Write-Host "  💡 팁: Tab 키로 Plan 모드 전환 → /start-work 로 플랜 실행!" -ForegroundColor DarkGray
  Write-Host ""
}

function Main {
  if ($env:OS -ne "Windows_NT") {
    Write-Err "이 스크립트는 Windows 전용입니다."
    Write-Info "macOS: bash <(curl -fsSL https://raw.githubusercontent.com/hyungwoon/ai-dev-setup/main/setup.sh)"
    exit 1
  }

  Write-Header

  Write-Host "  이 스크립트는 다음을 한 번에 설치합니다:" -ForegroundColor DarkGray
  Write-Host ""
  Write-Host "    • Git, Node.js, Bun              (기본 도구)" -ForegroundColor DarkGray
  Write-Host "    • Windows Terminal                (터미널)" -ForegroundColor DarkGray
  Write-Host "    • GitHub CLI                      (GitHub 연동)" -ForegroundColor DarkGray
  Write-Host "    • Claude Code                     (Anthropic CLI)" -ForegroundColor DarkGray
  Write-Host "    • OpenCode + oh-my-opencode       (AI 코딩 에이전트)" -ForegroundColor DarkGray
  Write-Host "    • 필수 플러그인 5개                 (알림, 토큰절약, 메모리 등)" -ForegroundColor DarkGray
  Write-Host ""

  if (-not (Read-YesNo "설치를 시작하시겠습니까?" "y")) {
    Write-Host "`n  취소됨" -ForegroundColor DarkGray
    exit 0
  }

  Install-WingetCheck
  Install-Git
  Install-Node
  Install-Bun
  Install-WindowsTerminal
  Install-GitHubCLI
  Install-ClaudeCode
  Install-OpenCode
  Install-Omo
  Install-Plugins
  Write-DoneMsg
}

Main
