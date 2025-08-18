## 📌 Description

<!-- Summarize what this PR does:

• What is the purpose of these changes?
• What problem does it solve, or what feature does it add?
• Brief background or context (if relevant). -->

<!-- ℹ️ **Fixes / Related Issues**
Fixes: `#123`
Related: `#456` -->

---

## 🧱 Type of Change

- [ ] 🐛 **Bug fix** – Non-breaking fix for a functional/logic error
- [ ] ✨ **New feature** – Adds functionality without breaking existing OAuth2 flows or APIs
- [ ] ⚠️ **Breaking change** – Backward-incompatible change (OAuth2 endpoints, token format, etc.)
- [ ] 📝 **Documentation update** – README, comments, API docs, etc.
- [ ] 🧪 **Test suite change** – Adds/updates unit, integration, or manual tests
- [ ] ⚙️ **CI/CD pipeline update** – GitHub Actions, Docker, pre-commit, etc.
- [ ] 🧹 **Refactor** – Code cleanup, improvements, or style changes
- [ ] 🐢 **Performance improvement** – Faster OAuth2 flows or reduced resource use
- [ ] 🕵️ **Logging/debugging** – Improved diagnostics, logs, or debug output
- [ ] 🔧 **Tooling** – Scripts, benchmarks, or local dev improvements
- [ ] 🔒 **Security fix** – OAuth2 vulnerabilities, token validation, or PESU API-related security issues
- [ ] 🧰 **Dependency update** – Library or package updates

---

## 🧪 How Has This Been Tested?

- [ ] Unit Tests
- [ ] Integration Tests
- [ ] Manual testing with OAuth2 flows
- [ ] CI / pre-commit run

>

**Test Environment:**

• OS: (e.g., `macOS`)
• Node.js: (e.g., `20.x`)
• Next.js version: (e.g., `15.4.6`)
• Database: (e.g., `MongoDB`)

---

## ✅ Checklist

- [ ] My code follows repo [CONTRIBUTING.md](https://github.com/pesu-dev/oauth2/blob/main/.github/CONTRIBUTING.md) guidelines
- [ ] Self-review completed
- [ ] Added/updated comments and docstrings
- [ ] Updated relevant docs (README, API docs, etc.)
- [ ] No new warnings or errors introduced
- [ ] Added/updated tests
- [ ] All tests pass locally
- [ ] Ran linting and formatting (`pnpm lint`)
- [ ] Docker image builds and runs
- [ ] Did not expose sensitive OAuth2 credentials or secrets
- [ ] Changes are backwards compatible (if applicable)
- [ ] Environment variables updated (if applicable)
- [ ] Tested OAuth2 flows end-to-end (if applicable)
- [ ] Database migrations tested (if applicable)

---

## 🛠️ Affected OAuth2 Areas

- [ ] **OAuth2 Endpoints** (`/oauth/authorize`, `/oauth/token`, etc.)
- [ ] **PESU Authentication Integration**
- [ ] **Token Management** (access tokens, refresh tokens, authorization codes)
- [ ] **Client Management** (registration, validation, secrets)
- [ ] **Database/Storage** (MongoDB, Prisma models)
- [ ] **Security/Validation** (input validation, rate limiting, CORS)
- [ ] **API Routes** (Next.js API routes)
- [ ] **Frontend/UI** (authorization pages, consent forms)
- [ ] **Middleware** (authentication, CORS, security headers)
- [ ] **CI/CD** (GitHub Actions, deployment)
- [ ] **Dependencies** (`package.json`, `pnpm-lock.yaml`)
- [ ] **Configuration** (environment variables, Next.js config)
- [ ] **Other** (specify in Additional Notes)

---

## 📸 Screenshots / Demos (if applicable)

<!-- Add screenshots of UI changes, OAuth2 flow diagrams, or terminal output -->

---

## 🧠 Additional Notes

<!-- Any additional information, deployment notes, or special considerations -->
