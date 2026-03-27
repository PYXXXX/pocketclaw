#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-}"
if [[ -z "$TARGET" ]]; then
  GLOBAL_NPM_ROOT="$(npm root -g)"
  OPENCLAW_DIR="$GLOBAL_NPM_ROOT/openclaw"
  TARGET="$OPENCLAW_DIR/node_modules/@mariozechner/pi-ai/dist/providers/openai-codex-responses.js"
fi

if [[ ! -f "$TARGET" ]]; then
  echo "target not found: $TARGET" >&2
  exit 1
fi

python3 - "$TARGET" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
s = p.read_text()

PATCH_MARKER = 'function isOfficialCodexBaseUrl(baseUrl)'

legacy_old1 = '''            const accountId = extractAccountId(apiKey);
            let body = buildRequestBody(model, context, options);
            const nextBody = await options?.onPayload?.(body, model);
            if (nextBody !== undefined) {
                body = nextBody;
            }
            const headers = buildHeaders(model.headers, options?.headers, accountId, apiKey, options?.sessionId);
'''
legacy_new1 = '''            const accountId = extractAccountId(apiKey, model.baseUrl);
            let body = buildRequestBody(model, context, options);
            const nextBody = await options?.onPayload?.(body, model);
            if (nextBody !== undefined) {
                body = nextBody;
            }
            const headers = buildHeaders(model.headers, options?.headers, accountId, apiKey, options?.sessionId, model.baseUrl);
'''

legacy_old2 = '''function extractAccountId(token) {
    try {
        const parts = token.split(".");
        if (parts.length !== 3)
            throw new Error("Invalid token");
        const payload = JSON.parse(atob(parts[1]));
        const accountId = payload?.[JWT_CLAIM_PATH]?.chatgpt_account_id;
        if (!accountId)
            throw new Error("No account ID in token");
        return accountId;
    }
    catch {
        throw new Error("Failed to extract accountId from token");
    }
}
function buildHeaders(initHeaders, additionalHeaders, accountId, token, sessionId) {
    const headers = new Headers(initHeaders);
    headers.set("Authorization", `Bearer ${token}`);
    headers.set("chatgpt-account-id", accountId);
    headers.set("OpenAI-Beta", "responses=experimental");
'''
legacy_new2 = '''function isOfficialCodexBaseUrl(baseUrl) {
    const raw = typeof baseUrl === "string" ? baseUrl.trim() : "";
    if (!raw)
        return true;
    try {
        const host = new URL(raw).hostname.toLowerCase();
        return host === "chatgpt.com" || host === "api.openai.com";
    }
    catch {
        const normalized = raw.toLowerCase();
        return normalized.includes("chatgpt.com") || normalized.includes("api.openai.com");
    }
}
function extractAccountId(token, baseUrl) {
    if (!isOfficialCodexBaseUrl(baseUrl))
        return undefined;
    try {
        const parts = token.split(".");
        if (parts.length !== 3)
            throw new Error("Invalid token");
        const payload = JSON.parse(atob(parts[1]));
        const accountId = payload?.[JWT_CLAIM_PATH]?.chatgpt_account_id;
        if (!accountId)
            throw new Error("No account ID in token");
        return accountId;
    }
    catch {
        throw new Error("Failed to extract accountId from token");
    }
}
function buildHeaders(initHeaders, additionalHeaders, accountId, token, sessionId, baseUrl) {
    const headers = new Headers(initHeaders);
    headers.set("Authorization", `Bearer ${token}`);
    if (accountId)
        headers.set("chatgpt-account-id", accountId);
    if (isOfficialCodexBaseUrl(baseUrl))
        headers.set("OpenAI-Beta", "responses=experimental");
'''

modern_old1 = '''            const accountId = extractAccountId(apiKey);
            let body = buildRequestBody(model, context, options);
            const nextBody = await options?.onPayload?.(body, model);
            if (nextBody !== undefined) {
                body = nextBody;
            }
            const websocketRequestId = options?.sessionId || createCodexRequestId();
            const sseHeaders = buildSSEHeaders(model.headers, options?.headers, accountId, apiKey, options?.sessionId);
            const websocketHeaders = buildWebSocketHeaders(model.headers, options?.headers, accountId, apiKey, websocketRequestId);
'''
modern_new1 = '''            const accountId = extractAccountId(apiKey, model.baseUrl);
            let body = buildRequestBody(model, context, options);
            const nextBody = await options?.onPayload?.(body, model);
            if (nextBody !== undefined) {
                body = nextBody;
            }
            const websocketRequestId = options?.sessionId || createCodexRequestId();
            const sseHeaders = buildSSEHeaders(model.headers, options?.headers, accountId, apiKey, options?.sessionId, model.baseUrl);
            const websocketHeaders = buildWebSocketHeaders(model.headers, options?.headers, accountId, apiKey, websocketRequestId, model.baseUrl);
'''

modern_old2 = '''function extractAccountId(token) {
    try {
        const parts = token.split(".");
        if (parts.length !== 3)
            throw new Error("Invalid token");
        const payload = JSON.parse(atob(parts[1]));
        const accountId = payload?.[JWT_CLAIM_PATH]?.chatgpt_account_id;
        if (!accountId)
            throw new Error("No account ID in token");
        return accountId;
    }
    catch {
        throw new Error("Failed to extract accountId from token");
    }
}
function createCodexRequestId() {
'''
modern_new2 = '''function isOfficialCodexBaseUrl(baseUrl) {
    const raw = typeof baseUrl === "string" ? baseUrl.trim() : "";
    if (!raw)
        return true;
    try {
        const host = new URL(raw).hostname.toLowerCase();
        return host === "chatgpt.com" || host === "api.openai.com";
    }
    catch {
        const normalized = raw.toLowerCase();
        return normalized.includes("chatgpt.com") || normalized.includes("api.openai.com");
    }
}
function extractAccountId(token, baseUrl) {
    if (!isOfficialCodexBaseUrl(baseUrl))
        return undefined;
    try {
        const parts = token.split(".");
        if (parts.length !== 3)
            throw new Error("Invalid token");
        const payload = JSON.parse(atob(parts[1]));
        const accountId = payload?.[JWT_CLAIM_PATH]?.chatgpt_account_id;
        if (!accountId)
            throw new Error("No account ID in token");
        return accountId;
    }
    catch {
        throw new Error("Failed to extract accountId from token");
    }
}
function createCodexRequestId() {
'''

modern_old3 = '''function buildBaseCodexHeaders(initHeaders, additionalHeaders, accountId, token) {
    const headers = new Headers(initHeaders);
    for (const [key, value] of Object.entries(additionalHeaders || {})) {
        headers.set(key, value);
    }
    headers.set("Authorization", `Bearer ${token}`);
    headers.set("chatgpt-account-id", accountId);
    headers.set("originator", "pi");
    const userAgent = _os ? `pi (${_os.platform()} ${_os.release()}; ${_os.arch()})` : "pi (browser)";
    headers.set("User-Agent", userAgent);
    return headers;
}
function buildSSEHeaders(initHeaders, additionalHeaders, accountId, token, sessionId) {
    const headers = buildBaseCodexHeaders(initHeaders, additionalHeaders, accountId, token);
    headers.set("OpenAI-Beta", "responses=experimental");
    headers.set("accept", "text/event-stream");
    headers.set("content-type", "application/json");
    if (sessionId) {
        headers.set("session_id", sessionId);
    }
    return headers;
}
function buildWebSocketHeaders(initHeaders, additionalHeaders, accountId, token, requestId) {
    const headers = buildBaseCodexHeaders(initHeaders, additionalHeaders, accountId, token);
    headers.delete("accept");
    headers.delete("content-type");
    headers.delete("OpenAI-Beta");
    headers.delete("openai-beta");
    headers.set("OpenAI-Beta", OPENAI_BETA_RESPONSES_WEBSOCKETS);
    headers.set("x-client-request-id", requestId);
    headers.set("session_id", requestId);
    return headers;
}
'''
modern_new3 = '''function buildBaseCodexHeaders(initHeaders, additionalHeaders, accountId, token) {
    const headers = new Headers(initHeaders);
    for (const [key, value] of Object.entries(additionalHeaders || {})) {
        headers.set(key, value);
    }
    headers.set("Authorization", `Bearer ${token}`);
    if (accountId)
        headers.set("chatgpt-account-id", accountId);
    headers.set("originator", "pi");
    const userAgent = _os ? `pi (${_os.platform()} ${_os.release()}; ${_os.arch()})` : "pi (browser)";
    headers.set("User-Agent", userAgent);
    return headers;
}
function buildSSEHeaders(initHeaders, additionalHeaders, accountId, token, sessionId, baseUrl) {
    const headers = buildBaseCodexHeaders(initHeaders, additionalHeaders, accountId, token);
    if (isOfficialCodexBaseUrl(baseUrl))
        headers.set("OpenAI-Beta", "responses=experimental");
    headers.set("accept", "text/event-stream");
    headers.set("content-type", "application/json");
    if (sessionId) {
        headers.set("session_id", sessionId);
    }
    return headers;
}
function buildWebSocketHeaders(initHeaders, additionalHeaders, accountId, token, requestId, baseUrl) {
    const headers = buildBaseCodexHeaders(initHeaders, additionalHeaders, accountId, token);
    headers.delete("accept");
    headers.delete("content-type");
    headers.delete("OpenAI-Beta");
    headers.delete("openai-beta");
    if (isOfficialCodexBaseUrl(baseUrl))
        headers.set("OpenAI-Beta", OPENAI_BETA_RESPONSES_WEBSOCKETS);
    headers.set("x-client-request-id", requestId);
    headers.set("session_id", requestId);
    return headers;
}
'''

if PATCH_MARKER in s:
    print('already patched')
else:
    if modern_old1 in s and modern_old2 in s and modern_old3 in s:
        s = s.replace(modern_old1, modern_new1, 1)
        s = s.replace(modern_old2, modern_new2, 1)
        s = s.replace(modern_old3, modern_new3, 1)
        p.write_text(s)
        print('patched modern upstream')
    elif legacy_old1 in s and legacy_old2 in s:
        s = s.replace(legacy_old1, legacy_new1, 1)
        s = s.replace(legacy_old2, legacy_new2, 1)
        p.write_text(s)
        print('patched legacy upstream')
    else:
        raise SystemExit('patch hunks not found for known upstream layouts')
PY

node --check "$TARGET" >/dev/null
printf 'ok: %s\n' "$TARGET"
