# Buddian iOS — MVP TODO

Step-by-step plan for the MVP. See [README.md](README.md) for full spec.
See [DONE.md](DONE.md) for completed steps.

---

## Phase 1: Scaffold ✅ (Steps 1-12)

All scaffold steps complete. See [DONE.md](DONE.md).

---

## Phase 2: Backend Integration

### ~~Step 13: Fetch Models from API~~ ✅

- ~~Extend `APIClient` with `/models` endpoint~~
- ~~Create `ModelResponse` Codable struct matching backend schema~~
- ~~Replace hardcoded `AIModel.allModels` with API-fetched data~~
- ~~Show loading state and error handling~~
- ~~Verify: models list shows real data from api.buddian.com~~
- ~~Commit: fetch models from API~~

### Step 14: Session Management

- Store session token in UserDefaults (after auth)
- Add session token to API requests via Authorization header
- Create `SessionManager` to handle token lifecycle
- Verify: token persists across app launches
- Commit: session management

### Step 15: Account & Balance

- Add `/web/me` endpoint to fetch profile, balance, transactions
- Create `AccountResponse` and `Transaction` models
- Update WalletView to display real balance and transactions
- Verify: wallet shows real data when logged in
- Commit: account and balance

### Step 16: Ask Tab — Real Inference

- Add `/pricing/chat-quote` endpoint for cost estimation
- Wire Generate button to submit prompts via API
- Show generation status in Library tab
- Verify: submitting a prompt creates a job
- Commit: ask tab inference

---

## Phase 3: Polish & Ship

### Step 17: Error Handling & Loading States

- Add loading spinners for API calls
- Show user-friendly error alerts
- Handle network offline gracefully
- Verify: no crashes on network errors
- Commit: error handling

### Step 18: Final Build & TestFlight

- Full clean build
- Archive for TestFlight
- Verify all tabs work end-to-end
- Commit: ready for TestFlight
