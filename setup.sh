#!/bin/bash
#
#  🚀 AI 개발환경 원클릭 설치 스크립트
#  비개발자를 위한 올인원 셋업
#
#  설치 항목:
#    Homebrew · Git · fnm · Node.js · Bun · pnpm · Warp Terminal
#    GitHub CLI · Claude Code · OpenCode · Vercel · Supabase
#    Docker · uv · oh-my-opencode
#
#  사용법:
#    bash <(curl -fsSL https://raw.githubusercontent.com/hyungwoon/ai-dev-setup/main/setup.sh)
#
set -euo pipefail

# ── 색상 ──────────────────────────────────────────────
R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m'
B='\033[0;34m' P='\033[0;35m' C='\033[0;36m'
W='\033[1;37m' D='\033[2m'    N='\033[0m'

# ── 출력 헬퍼 ─────────────────────────────────────────
_n=0
header() {
  clear
  echo ""
  echo -e "${P}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
  echo -e "${W}  🚀 AI 개발환경 원클릭 설치${N}"
  echo -e "${D}     Warp · Claude Code · OpenCode · oh-my-opencode${N}"
  echo -e "${D}     Vercel · Supabase · Docker · uv${N}"
  echo -e "${P}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
  echo ""
}
step() { _n=$((_n+1)); echo ""; echo -e "${B}[$_n]${N} ${W}$1${N}"; echo -e "${D}──────────────────────────────────────${N}"; }
ok()   { echo -e "  ${G}✓${N} $1"; }
warn() { echo -e "  ${Y}⚠${N} $1"; }
err()  { echo -e "  ${R}✗${N} $1"; }
skip() { echo -e "  ${D}→ 이미 설치됨: $1${N}"; }
info() { echo -e "  ${C}ℹ${N} $1"; }

has() { command -v "$1" &>/dev/null; }

yn() {
  local prompt="$1" default="${2:-n}" answer
  if [[ "$default" == "y" ]]; then
    echo -en "  ${W}${prompt}${N} ${D}[Y/n]${N} " >&2
  else
    echo -en "  ${W}${prompt}${N} ${D}[y/N]${N} " >&2
  fi
  read -r answer < /dev/tty
  answer="${answer:-$default}"
  [[ "$answer" =~ ^[Yy] ]]
}

choose() {
  local prompt="$1"; shift; local opts=("$@")
  echo -e "  ${W}${prompt}${N}" >&2
  for i in "${!opts[@]}"; do
    echo -e "    ${C}$((i+1))${N}) ${opts[$i]}" >&2
  done
  echo -en "  ${D}번호를 선택하세요:${N} " >&2
  local c; read -r c < /dev/tty
  echo "$c"
}

brew_path() {
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

# ── 1. Xcode CLI Tools ───────────────────────────────
do_xcode() {
  step "Xcode Command Line Tools"
  if xcode-select -p &>/dev/null; then
    skip "Xcode CLI Tools"
  else
    info "Xcode CLI Tools를 설치합니다."
    info "팝업이 뜨면 ${W}'설치'${N}를 클릭하세요."
    xcode-select --install 2>/dev/null || true
    echo ""
    echo -en "  ${D}설치가 완료되면 Enter를 눌러주세요...${N}" >&2
    read -r < /dev/tty
    if xcode-select -p &>/dev/null; then
      ok "설치 완료"
    else
      err "설치 실패 — 수동으로 설치 후 다시 실행해주세요."
      exit 1
    fi
  fi
}

# ── 2. Homebrew ───────────────────────────────────────
do_brew() {
  step "Homebrew (macOS 패키지 관리자)"
  brew_path
  if has brew; then
    skip "Homebrew"
  else
    info "Homebrew를 설치합니다... (비밀번호 입력이 필요할 수 있습니다)"
    NONINTERACTIVE=0 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" < /dev/tty
    brew_path
    # 향후 터미널 세션용 PATH 등록
    if [[ -f /opt/homebrew/bin/brew ]] && ! grep -q 'homebrew' "${HOME}/.zprofile" 2>/dev/null; then
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "${HOME}/.zprofile"
    fi
    has brew && ok "설치 완료" || { err "설치 실패"; exit 1; }
  fi
}

# ── 3. Git ────────────────────────────────────────────
do_git() {
  step "Git (버전 관리)"
  if has git; then
    skip "Git $(git --version | awk '{print $3}')"
  else
    brew install git
    ok "Git 설치 완료"
  fi
}

# ── 4. fnm + Node.js LTS ──────────────────────────────
do_fnm() {
  step "fnm + Node.js LTS (JavaScript 런타임)"
  if has fnm; then
    skip "fnm"
  else
    brew install fnm
    has fnm && ok "fnm 설치 완료" || { err "fnm 설치 실패"; exit 1; }
  fi
  if has fnm; then
    eval "$(fnm env --use-on-cd)" 2>/dev/null
    if has node; then
      skip "Node.js $(node --version)"
    else
      info "Node.js LTS를 설치합니다..."
      fnm install --lts 2>/dev/null && fnm use lts-latest 2>/dev/null
      has node && ok "Node.js $(node --version) 설치 완료" \
        || warn "Node.js 설치 확인 필요 — 터미널 재시작 후 확인하세요."
    fi
    if ! grep -q 'fnm env' "${HOME}/.zshrc" 2>/dev/null; then
      echo 'eval "$(fnm env --use-on-cd)"' >> "${HOME}/.zshrc"
      info ".zshrc에 fnm PATH 등록 완료"
    fi
  fi
}

# ── 5. Bun ────────────────────────────────────────────
do_bun() {
  step "Bun (빠른 JavaScript 런타임)"
  if has bun; then
    skip "Bun $(bun --version)"
  else
    curl -fsSL https://bun.sh/install | bash
    export BUN_INSTALL="${HOME}/.bun"
    export PATH="${BUN_INSTALL}/bin:${PATH}"
    has bun && ok "Bun $(bun --version) 설치 완료" || { err "설치 실패"; exit 1; }
  fi
}

# ── 6. pnpm ───────────────────────────────────────────
do_pnpm() {
  step "pnpm (빠른 패키지 매니저)"
  if has pnpm; then
    skip "pnpm $(pnpm --version 2>/dev/null)"
  else
    brew install pnpm
    has pnpm && ok "pnpm 설치 완료" || { err "설치 실패"; exit 1; }
  fi
}

# ── 7. Warp Terminal ──────────────────────────────────
do_warp() {
  step "Warp Terminal (AI 터미널)"
  if [[ -d "/Applications/Warp.app" ]]; then
    skip "Warp Terminal"
  else
    info "Warp Terminal을 설치합니다..."
    brew install --cask warp
    if [[ -d "/Applications/Warp.app" ]]; then
      ok "설치 완료"
      info "설치 후 Warp를 한번 실행해 초기 설정을 완료하세요."
    else
      warn "자동 설치 실패 — https://warp.dev 에서 직접 다운로드하세요."
    fi
  fi
}

# ── 7. GitHub CLI ─────────────────────────────────────
do_gh() {
  step "GitHub CLI"
  if has gh; then
    skip "GitHub CLI $(gh --version 2>/dev/null | head -1 | awk '{print $3}')"
  else
    brew install gh
    ok "GitHub CLI 설치 완료"
  fi
  if ! gh auth status &>/dev/null 2>&1; then
    info "GitHub 로그인이 필요합니다."
    if yn "지금 GitHub에 로그인하시겠습니까?" "y"; then
      gh auth login < /dev/tty
    else
      warn "나중에 ${C}gh auth login${N} 으로 로그인하세요."
    fi
  fi
}

# ── 8. Claude Code ────────────────────────────────────
do_claude() {
  step "Claude Code (Anthropic CLI)"
  if has claude; then
    skip "Claude Code"
  else
    info "Claude Code를 설치합니다..."
    npm install -g @anthropic-ai/claude-code
    has claude && ok "설치 완료" || warn "설치 확인 필요 — 터미널을 재시작 후 ${C}claude${N} 명령어를 확인하세요."
  fi
}

# ── 9. OpenCode ───────────────────────────────────────
do_opencode() {
  step "OpenCode (AI 코딩 에이전트)"
  if has opencode; then
    skip "OpenCode $(opencode --version 2>/dev/null || echo '')"
  else
    info "OpenCode를 설치합니다..."
    if brew install anomalyco/tap/opencode 2>/dev/null; then
      ok "설치 완료 (Homebrew)"
    elif curl -fsSL https://opencode.ai/install | bash 2>/dev/null; then
      ok "설치 완료"
    else
      err "자동 설치 실패"
      info "https://opencode.ai/docs 에서 수동 설치 후 Enter를 눌러주세요."
      read -r < /dev/tty
    fi
  fi
}

# ── 11. Vercel CLI ────────────────────────────────────
do_vercel() {
  step "Vercel CLI (배포)"
  if has vercel; then
    skip "Vercel CLI"
  else
    if has npm; then
      npm install -g vercel
      has vercel && ok "Vercel CLI 설치 완료" || warn "설치 확인 필요"
    else
      warn "npm이 없습니다 — Node.js 설치 후 재시도하세요."
    fi
  fi
}

# ── 12. Supabase CLI ─────────────────────────────────
do_supabase() {
  step "Supabase CLI (백엔드/DB)"
  if has supabase; then
    skip "Supabase CLI"
  else
    brew install supabase/tap/supabase
    has supabase && ok "Supabase CLI 설치 완료" || { err "설치 실패"; exit 1; }
  fi
}

# ── 13. Docker ────────────────────────────────────────
do_docker() {
  step "Docker (컨테이너)"
  if [[ -d "/Applications/Docker.app" ]] || has docker; then
    skip "Docker"
  else
    info "Docker Desktop을 설치합니다..."
    brew install --cask docker
    if [[ -d "/Applications/Docker.app" ]]; then
      ok "설치 완료"
      info "Launchpad에서 Docker를 한번 실행해 초기 설정을 완료하세요."
    else
      warn "자동 설치 실패 — https://docker.com 에서 직접 다운로드하세요."
    fi
  fi
}

# ── 14. uv ────────────────────────────────────────────
do_uv() {
  step "uv (Python 패키지 매니저)"
  if has uv; then
    skip "uv"
  else
    curl -LsSf https://astral.sh/uv/install.sh | sh
    has uv && ok "uv 설치 완료" || warn "설치 확인 필요 — 터미널 재시작 후 확인하세요."
  fi
}

# ── 15. oh-my-opencode ───────────────────────────────
do_omo() {
  step "oh-my-opencode (OpenCode 플러그인)"
  echo ""
  echo -e "  ${P}━━━ AI 서비스 구독 정보 확인 ━━━${N}"
  echo -e "  ${D}현재 사용 중인 서비스를 선택해주세요.${N}"
  echo ""

  # ── Claude ──
  local claude_flag="no"
  local cc
  cc=$(choose "Claude (Anthropic) 구독이 있나요?" \
    "없음" \
    "Claude Pro / Max 구독 있음" \
    "Claude Max (max20 = 20배 모드) 사용 중")
  case "$cc" in
    2) claude_flag="yes" ;;
    3) claude_flag="max20" ;;
    *)
      claude_flag="no"
      echo ""
      warn "Claude 구독 없이는 Sisyphus 에이전트가 최적으로 작동하지 않을 수 있습니다."
      ;;
  esac

  # ── OpenAI ──
  local openai_flag="no"
  echo ""
  yn "ChatGPT Plus / OpenAI 구독이 있나요?" && openai_flag="yes"

  # ── Gemini ──
  local gemini_flag="no"
  echo ""
  yn "Google Gemini를 사용하나요?" && gemini_flag="yes"

  # ── GitHub Copilot ──
  local copilot_flag="no"
  echo ""
  yn "GitHub Copilot 구독이 있나요?" && copilot_flag="yes"

  # ── OpenCode Zen ──
  local zen_flag="no"
  echo ""
  yn "OpenCode Zen을 사용하나요?" && zen_flag="yes"

  # ── Z.ai ──
  local zai_flag="no"
  echo ""
  yn "Z.ai Coding Plan을 사용하나요?" && zai_flag="yes"

  # ── OpenCode Go ──
  local go_flag="no"
  echo ""
  yn "OpenCode Go (\$10/월 — GLM-5, Kimi K2.5 등)를 사용하나요?" && go_flag="yes"

  # ── 설치 실행 ──
  echo ""
  local cmd="bunx oh-my-opencode install --no-tui"
  cmd+=" --claude=${claude_flag}"
  cmd+=" --openai=${openai_flag}"
  cmd+=" --gemini=${gemini_flag}"
  cmd+=" --copilot=${copilot_flag}"
  cmd+=" --opencode-zen=${zen_flag}"
  cmd+=" --zai-coding-plan=${zai_flag}"
  cmd+=" --opencode-go=${go_flag}"

  info "실행: ${cmd}"
  echo ""
  eval "$cmd"
  echo ""
  ok "oh-my-opencode 설치 완료"
}

# ── 11. 필수 플러그인 ─────────────────────────────────
do_plugins() {
  step "필수 플러그인 설치"
  echo ""
  echo -e "  ${D}OpenCode 경험을 향상시키는 핵심 플러그인을 추가합니다.${N}"
  echo ""

  local config_dir="${HOME}/.config/opencode"
  local config_file="${config_dir}/opencode.json"
  mkdir -p "$config_dir"

  node << 'NODEJS'
const fs = require("fs");
const path = require("path");
const p = path.join(process.env.HOME, ".config/opencode/opencode.json");
let c = {};
try { c = JSON.parse(fs.readFileSync(p, "utf8")); } catch {}
if (!c["$schema"]) c["$schema"] = "https://opencode.ai/config.json";
if (!c.plugin) c.plugin = [];
["opencode-notificator","opencode-dynamic-context-pruning","opencode-supermemory","opencode-worktree","opencode-vibeguard"]
  .forEach(x => { if (!c.plugin.includes(x)) c.plugin.push(x); });
fs.mkdirSync(path.dirname(p), { recursive: true });
fs.writeFileSync(p, JSON.stringify(c, null, 2) + "\n");
NODEJS

  ok "opencode-notificator       — 작업 완료 데스크톱 알림"
  ok "opencode-dynamic-context-pruning — 토큰 자동 절약"
  ok "opencode-supermemory       — 세션 간 기억 유지"
  ok "opencode-worktree          — Git worktree 자동화"
  ok "opencode-vibeguard         — 비밀 정보 자동 보호"
  echo ""
  info "다음 opencode 실행 시 자동으로 설치됩니다."
}

# ── 완료 메시지 ───────────────────────────────────────
done_msg() {
  echo ""
  echo -e "${G}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
  echo -e "${W}  ✅ 모든 설치가 완료되었습니다!${N}"
  echo -e "${G}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
  echo ""

  echo -e "  ${W}설치 결과:${N}"
  has brew      && echo -e "    ${G}✓${N} Homebrew"
  has git       && echo -e "    ${G}✓${N} Git"
  has fnm       && echo -e "    ${G}✓${N} fnm"
  has node      && echo -e "    ${G}✓${N} Node.js $(node --version 2>/dev/null)"
  has bun       && echo -e "    ${G}✓${N} Bun $(bun --version 2>/dev/null)"
  has pnpm      && echo -e "    ${G}✓${N} pnpm $(pnpm --version 2>/dev/null)"
  [[ -d "/Applications/Warp.app" ]] && echo -e "    ${G}✓${N} Warp Terminal"
  has gh        && echo -e "    ${G}✓${N} GitHub CLI"
  has claude    && echo -e "    ${G}✓${N} Claude Code"
  has opencode  && echo -e "    ${G}✓${N} OpenCode"
  has vercel    && echo -e "    ${G}✓${N} Vercel CLI"
  has supabase  && echo -e "    ${G}✓${N} Supabase CLI"
  ([[ -d "/Applications/Docker.app" ]] || has docker) && echo -e "    ${G}✓${N} Docker"
  has uv        && echo -e "    ${G}✓${N} uv"
  echo -e "    ${G}✓${N} oh-my-opencode"
  echo -e "    ${G}✓${N} 필수 플러그인 5개"

  echo ""
  echo -e "  ${W}다음 단계:${N}"
  echo ""
  echo -e "    ${C}1.${N} 서비스 로그인:"
  echo -e "       ${C}gh auth login${N}        — GitHub 인증"
  echo -e "       ${C}vercel login${N}         — Vercel 인증"
  echo -e "       ${C}supabase login${N}       — Supabase 인증"
  echo -e "       ${C}opencode auth login${N}  — OpenCode 인증"
  echo -e "       터미널에서 ${C}claude${N} 입력  — Claude Code 인증"
  echo ""
  echo -e "    ${C}2.${N} 아무 프로젝트 폴더에서 시작:"
  echo -e "       ${C}cd ~/my-project && opencode${N}"
  echo ""
  echo -e "  ${D}──────────────────────────────────────${N}"
  echo -e "  ${D}💡 팁: 프롬프트에 'ultrawork'를 포함하면 자동으로 끝까지 작업합니다.${N}"
  echo -e "  ${D}💡 팁: Tab 키로 Plan 모드 전환 → /start-work 로 플랜 실행!${N}"
  echo ""
}

# ── 메인 ──────────────────────────────────────────────
main() {
  if [[ "$(uname)" != "Darwin" ]]; then
    err "이 스크립트는 macOS 전용입니다."
    exit 1
  fi

  header

  echo -e "  ${D}이 스크립트는 다음을 한 번에 설치합니다:${N}"
  echo ""
  echo -e "    • Homebrew, Git, fnm, Node.js, Bun, pnpm  ${D}(기본 도구)${N}"
  echo -e "    • Warp Terminal                            ${D}(AI 터미널)${N}"
  echo -e "    • GitHub CLI                               ${D}(GitHub 연동)${N}"
  echo -e "    • Claude Code                              ${D}(Anthropic CLI)${N}"
  echo -e "    • OpenCode + oh-my-opencode                ${D}(AI 코딩 에이전트)${N}"
  echo -e "    • Vercel CLI, Supabase CLI                 ${D}(배포/백엔드)${N}"
  echo -e "    • Docker, uv                               ${D}(컨테이너/Python)${N}"
  echo ""

  yn "설치를 시작하시겠습니까?" "y" || { echo -e "\n  ${D}취소됨${N}"; exit 0; }

  do_xcode
  do_brew
  do_git
  do_fnm
  do_bun
  do_pnpm
  do_warp
  do_gh
  do_claude
  do_opencode
  do_vercel
  do_supabase
  do_docker
  do_uv
  do_omo
  do_plugins
  done_msg
}

main "$@"
