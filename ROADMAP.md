# 🗺️ Project Roadmap — Stocks Serverless Pipeline

**Epic:** [SCRUM-5 — Stocks Serverless Project](https://madbusse.atlassian.net/browse/SCRUM-5)
**Project:** Personal Projects (SCRUM)
**Sprint Status:** Active
**Generated:** 2026-03-06

---

## Overview

Build a fully automated serverless pipeline on AWS that tracks a watchlist of tech stocks (AAPL, MSFT, GOOGL, AMZN, TSLA, NVDA), identifies the daily top mover by % change, stores results in DynamoDB, and displays a 7-day history on a public-facing SPA frontend.

---

## Phase 1 — Foundation & Infrastructure

### 🏗️ [SCRUM-6] Define AWS Infrastructure Using Terraform/CDK
**Type:** Story | **Status:** To Do | **Priority:** Medium
**Jira:** https://madbusse.atlassian.net/browse/SCRUM-6

Define all AWS resources as code using Terraform, AWS CDK, or Serverless Framework. No resources should be created manually via the AWS Console.

**Acceptance Criteria:**
- All resources (Lambda, EventBridge, DynamoDB, API Gateway, S3/Amplify) defined in IaC
- Code is clean, modular, and parameterized
- Consistent naming and tagging conventions applied
- Stack can be fully reproduced from scratch with a single deploy command

> 💡 **Bonus:** Set up a GitHub Actions CI/CD pipeline for auto-deploy.

---

### 🗄️ [SCRUM-9] Set Up DynamoDB Table for Storing Daily Top Movers
**Type:** Task | **Status:** To Do | **Priority:** Medium
**Jira:** https://madbusse.atlassian.net/browse/SCRUM-9

Provision the DynamoDB table to persist daily top mover records via IaC.

**Table Schema:**
| Field | Type | Notes |
|-------|------|-------|
| `date` | String (PK) | Format: YYYY-MM-DD |
| `ticker` | String | e.g. NVDA |
| `percentChange` | Number | e.g. 4.32 |
| `closingPrice` | Number | e.g. 134.50 |

**Acceptance Criteria:**
- Table provisioned via IaC (not manually)
- Ingestion Lambda has IAM write permissions (least privilege)
- Retrieval Lambda has IAM read-only permissions

---

### 🔐 [SCRUM-12] Configure Secrets Management and Least-Privilege IAM Roles
**Type:** Task | **Status:** To Do | **Priority:** Medium
**Jira:** https://madbusse.atlassian.net/browse/SCRUM-12

Ensure no secrets or credentials are exposed in the public GitHub repository.

**Requirements:**
- Add `.gitignore` to exclude `.env`, `terraform.tfstate`, and credential files
- Store the Stock API key as a Lambda environment variable (or AWS Secrets Manager)
- Do NOT commit AWS Access Keys, Secret Keys, or API tokens
- Apply least-privilege IAM roles to all Lambda functions

**Acceptance Criteria:**
- Public GitHub repo has no secrets in commit history
- `.gitignore` properly configured
- IAM roles scoped to minimum required permissions

---

## Phase 2 — Backend & Data Ingestion

### ⚡ [SCRUM-7] Build Daily Stock Ingestion Lambda with EventBridge Cron
**Type:** Story | **Status:** To Do | **Priority:** Medium
**Jira:** https://madbusse.atlassian.net/browse/SCRUM-7

Create an AWS Lambda function triggered daily by Amazon EventBridge to fetch stock data and identify the top mover.

**Watchlist:** `AAPL`, `MSFT`, `GOOGL`, `AMZN`, `TSLA`, `NVDA`

**Top Mover Logic:**
```
% Change = ((Close - Open) / Open) * 100
```
Ticker with the highest **absolute** % change wins.

**Acceptance Criteria:**
- EventBridge rule triggers Lambda every 24 hours
- Correctly identifies the top mover each day
- Stores clean, structured records to DynamoDB
- Ingestion logic is fully separate from retrieval logic

---

### 🛡️ [SCRUM-8] Implement Error Handling and API Rate Limit Retry Logic
**Type:** Task | **Status:** To Do | **Priority:** Medium
**Jira:** https://madbusse.atlassian.net/browse/SCRUM-8

Add resilience to the ingestion Lambda to handle external API failures gracefully.

**Requirements:**
- Catch and log errors if the stock API is down or returns unexpected data
- Implement retry logic with exponential backoff for rate limit (HTTP 429) responses
- Ensure partial failures (one ticker fails) don't crash the entire run
- Use CloudWatch for logging and alerting

> 💡 **Bonus:** Store the API key in AWS Secrets Manager instead of environment variables.

---

## Phase 3 — API Layer

### 🔌 [SCRUM-10] Create GET /movers REST Endpoint via API Gateway + Lambda
**Type:** Story | **Status:** To Do | **Priority:** Medium
**Jira:** https://madbusse.atlassian.net/browse/SCRUM-10

Build a REST API using API Gateway + Lambda that exposes stock mover history to the frontend.

**Endpoint:** `GET /movers`

**Example Response:**
```json
[
  { "date": "2025-01-01", "ticker": "NVDA", "percentChange": 4.32, "closingPrice": 134.50 },
  { "date": "2024-12-31", "ticker": "TSLA", "percentChange": -3.10, "closingPrice": 248.00 }
]
```

**Acceptance Criteria:**
- Returns last 7 days of winning stock records
- Proper HTTP status codes (200, 500, etc.)
- Handles edge cases (no data, DynamoDB errors)
- This Lambda is **separate** from the ingestion Lambda
- CORS enabled for frontend access

> 💡 **Bonus:** Implement response caching or pagination headers.

---

## Phase 4 — Frontend

### 🖥️ [SCRUM-11] Build and Host SPA Dashboard for Top Mover History
**Type:** Story | **Status:** To Do | **Priority:** Medium
**Jira:** https://madbusse.atlassian.net/browse/SCRUM-11

Build and deploy a Single Page Application that displays the 7-day top mover history.

**Requirements:**
- Fetch data from `GET /movers` on load
- Display in a table or card view: Date, Ticker, % Change, Closing Price
- 🟢 Green for positive % change (gain)
- 🔴 Red for negative % change (loss)
- Host on AWS S3 (Static Website Hosting) or AWS Amplify

**Accepted Tech:** Next.js, Vue, plain JS — any framework works.

**Acceptance Criteria:**
- App is publicly accessible via a URL
- Data fetches and renders correctly
- Green/Red color coding applied

> 💡 **Bonus:** Add charts/graphs or interactive elements.

---

## Phase 5 — Documentation & Delivery

### 📄 [SCRUM-13] Write README with Deployment Instructions and Architecture Overview
**Type:** Task | **Status:** To Do | **Priority:** Medium
**Jira:** https://madbusse.atlassian.net/browse/SCRUM-13

Write a clear `README.md` so any developer can deploy the full stack from scratch.

**README Should Cover:**
- Project overview and architecture diagram
- Prerequisites (AWS account, CLI, Terraform/CDK version, language runtime)
- Step-by-step deployment instructions
- How to configure the Stock API key
- How to tear down the stack
- Any trade-offs or known issues

**Acceptance Criteria:**
- A new developer can deploy the stack end-to-end using only the README
- No manual AWS Console steps required

---

## Ticket Summary

| Ticket | Type | Phase | Summary | Status |
|--------|------|-------|---------|--------|
| [SCRUM-6](https://madbusse.atlassian.net/browse/SCRUM-6) | Story | Foundation | Define AWS infrastructure (IaC) | To Do |
| [SCRUM-9](https://madbusse.atlassian.net/browse/SCRUM-9) | Task | Foundation | Set up DynamoDB table | To Do |
| [SCRUM-12](https://madbusse.atlassian.net/browse/SCRUM-12) | Task | Foundation | Secrets management & IAM roles | To Do |
| [SCRUM-7](https://madbusse.atlassian.net/browse/SCRUM-7) | Story | Backend | Daily ingestion Lambda + EventBridge cron | To Do |
| [SCRUM-8](https://madbusse.atlassian.net/browse/SCRUM-8) | Task | Backend | Error handling & retry logic | To Do |
| [SCRUM-10](https://madbusse.atlassian.net/browse/SCRUM-10) | Story | API | GET /movers endpoint | To Do |
| [SCRUM-11](https://madbusse.atlassian.net/browse/SCRUM-11) | Story | Frontend | SPA dashboard (hosted) | To Do |
| [SCRUM-13](https://madbusse.atlassian.net/browse/SCRUM-13) | Task | Docs | README & deployment guide | To Do |

---

## Suggested Build Order

```
Phase 1 (Foundation)
  SCRUM-6  →  SCRUM-9  →  SCRUM-12
        ↓
Phase 2 (Backend)
  SCRUM-7  →  SCRUM-8
        ↓
Phase 3 (API)
  SCRUM-10
        ↓
Phase 4 (Frontend)
  SCRUM-11
        ↓
Phase 5 (Docs)
  SCRUM-13
```

---

*Generated from active Jira sprint: [madbusse.atlassian.net](https://madbusse.atlassian.net)*