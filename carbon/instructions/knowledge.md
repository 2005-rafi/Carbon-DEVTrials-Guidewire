# Carbon API Knowledge Base (Live Contract + Runtime Probe)

Generated: 2026-04-14 19.33.15 UTC
Base URL: `http://18.207.159.194:8000/api/v1`
Sources:
- Live OpenAPI contract: `instructions/openapi_live.json` (44 operations)
- Live curl sweep: `instructions/endpoint_sweep_live.json`
- Historical probes: `instructions/phase*_probe_runtime.json`, `instructions/phase7_full_endpoint_smoke.json`

## Executive Summary
- Total operations discovered: 44
- Operations with successful live probe (`2xx`): 30
- Operations with non-success live probe: 14
- Consistently unstable domains from historical + live probes: `claims`, `trigger/mock`, `fraud`
- Security concern observed: several endpoints return successful responses without strict auth enforcement in probe artifacts.

## Runtime Defects (Observed)
- `POST /api/v1/auth/register` -> status `400`
- `GET /api/v1/claims/{user_id}` -> status `500`
- `POST /api/v1/claims/auto` -> status `404`
- `GET /api/v1/fraud/{claim_id}` -> status `500`
- `POST /api/v1/fraud/check` -> status `500`
- `POST /api/v1/fraud/override` -> status `500`
- `GET /api/v1/ledger/audit/{transaction_id}` -> status `404`
- `GET /api/v1/policy/{user_id}` -> status `404`
- `POST /api/v1/policy/create` -> status `404`
- `POST /api/v1/policy/opt-in` -> status `404`
- `POST /api/v1/policy/opt-out` -> status `404`
- `POST /api/v1/trigger/mock` -> status `500`
- `GET /api/v1/workers/{user_id}` -> status `404`
- `PUT /api/v1/workers/{user_id}` -> status `404`

## Endpoint Reference

### analytics

#### `GET /api/v1/analytics/dashboard`
- Operation ID: `get_dashboard_stats_api_v1_analytics_dashboard_get`
- Live probe status: `200` (`ok`)
- Parameters: none
- Request body: none
- Declared response codes: `200`
- Live probe request sample:
```json
{
    "query":  "",
    "content_type":  "",
    "body":  null
}
```
- Live probe response sample:
```json
{
    "total_workers":  28,
    "total_payout_amount":  200.0,
    "total_claims_count":  0,
    "active_policies":  4,
    "system_health":  "OPTIMAL",
    "last_updated":  "2026-04-14T13:35:26.835661"
}
```

#### `GET /api/v1/analytics/timeseries`
- Operation ID: `get_timeseries_api_v1_analytics_timeseries_get`
- Live probe status: `200` (`ok`)
- Parameters:

| name | in | type | required | description |
|---|---|---|---|---|
| `days` | `query` | `integer` | `no` |  |
- Request body: none
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "days=7",
    "content_type":  "",
    "body":  null
}
```
- Live probe response sample:
```json
[
    {
        "date":  "2026-04-08",
        "claims":  31,
        "payouts":  4667.12
    },
    {
        "date":  "2026-04-09",
        "claims":  7,
        "payouts":  2092.04
    },
    {
        "date":  "2026-04-10",
        "claims":  13,
        "payouts":  2931.63
    },
    {
        "date":  "2026-04-11",
        "claims":  30,
        "payouts":  3851.81
    },
    {
        "date":  "2026-04-12",
        "claims":  13,
        "payouts":  2881.75
    },
    {
        "date":  "2026-04-13",
        "claims":  40,
        "payouts":  840.51
    },
    {
        "date":  "2026-04-14",
        "claims":  23,
        "payouts":  391.12
    }
]
```

#### `GET /api/v1/analytics/zones`
- Operation ID: `get_zone_analytics_api_v1_analytics_zones_get`
- Live probe status: `200` (`ok`)
- Parameters: none
- Request body: none
- Declared response codes: `200`
- Live probe request sample:
```json
{
    "query":  "",
    "content_type":  "",
    "body":  null
}
```
- Live probe response sample:
```json
[
    {
        "zone":  "Downtown",
        "risk_level":  "LOW",
        "active_workers":  150
    },
    {
        "zone":  "Industrial",
        "risk_level":  "MEDIUM",
        "active_workers":  85
    },
    {
        "zone":  "Suburbs",
        "risk_level":  "SAFE",
        "active_workers":  210
    }
]
```

### auth

#### `POST /api/v1/auth/login`
- Operation ID: `login_api_v1_auth_login_post`
- Live probe status: `200` (`ok`)
- Parameters: none
- Request body media type: `application/json`

| field | type | required | description |
|---|---|---|---|
| `phone` | `string` | `yes` |  |
| `otp` | `string` | `yes` |  |
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "",
    "content_type":  "application/json",
    "body":  {
                 "phone":  "9876543210",
                 "otp":  "123456"
             }
}
```
- Live probe response sample:
```json
{
    "access_token":  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI5ODc2NTQzMjEwIiwiZXhwIjoxNzc2MjYwMTEzfQ.C56JSRbj_9YtQ77DUIGtZAWlSLr3dh1PUzYceHAb2QA",
    "refresh_token":  "ref_6d7525db77cc49a7a9607504fc473a40",
    "user_id":  "1f4029bd-b5b8-4282-98d7-e37ee94721d1",
    "token_type":  "bearer"
}
```

#### `POST /api/v1/auth/logout`
- Operation ID: `logout_api_v1_auth_logout_post`
- Live probe status: `200` (`ok`)
- Parameters: none
- Request body: none
- Declared response codes: `200`
- Live probe request sample:
```json
{
    "query":  "",
    "content_type":  "",
    "body":  null
}
```
- Live probe response sample:
```json
{
    "message":  "Successfully logged out"
}
```

#### `POST /api/v1/auth/otp/send`
- Operation ID: `send_otp_api_v1_auth_otp_send_post`
- Live probe status: `200` (`ok`)
- Parameters: none
- Request body media type: `application/json`
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "",
    "content_type":  "application/json",
    "body":  {
                 "phone":  "9876543210"
             }
}
```
- Live probe response sample:
```json
{
    "message":  "OTP sent successfully"
}
```

#### `POST /api/v1/auth/otp/verify`
- Operation ID: `verify_otp_api_v1_auth_otp_verify_post`
- Live probe status: `200` (`ok`)
- Parameters: none
- Request body media type: `application/json`

| field | type | required | description |
|---|---|---|---|
| `phone` | `string` | `yes` |  |
| `otp` | `string` | `yes` |  |
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "",
    "content_type":  "application/json",
    "body":  {
                 "phone":  "9876543210",
                 "otp":  "123456"
             }
}
```
- Live probe response sample:
```json
{
    "access_token":  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI5ODc2NTQzMjEwIiwiZXhwIjoxNzc2MjYwMTEyfQ.D1ASloveepLosD1mhXkJD3OhsLtcHkKiCvDVpYyV5cw",
    "refresh_token":  "mock_refresh_token",
    "user_id":  "1f4029bd-b5b8-4282-98d7-e37ee94721d1",
    "token_type":  "bearer"
}
```

#### `POST /api/v1/auth/refresh`
- Operation ID: `refresh_token_api_v1_auth_refresh_post`
- Live probe status: `200` (`ok`)
- Parameters: none
- Request body: none
- Declared response codes: `200`
- Live probe request sample:
```json
{
    "query":  "",
    "content_type":  "",
    "body":  null
}
```
- Live probe response sample:
```json
{
    "access_token":  "new_mock_token",
    "refresh_token":  "new_mock_refresh"
}
```

#### `POST /api/v1/auth/register`
- Operation ID: `register_api_v1_auth_register_post`
- Live probe status: `400` (`not_ok`)
- Parameters: none
- Request body media type: `application/json`

| field | type | required | description |
|---|---|---|---|
| `phone` | `string` | `yes` |  |
| `full_name` | `object` | `no` |  |
| `email` | `object` | `no` |  |
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "",
    "content_type":  "application/json",
    "body":  {
                 "phone":  "9876543210"
             }
}
```

#### `GET /api/v1/auth/validate`
- Operation ID: `validate_token_api_v1_auth_validate_get`
- Live probe status: `200` (`ok`)
- Parameters: none
- Request body: none
- Declared response codes: `200`
- Live probe request sample:
```json
{
    "query":  "",
    "content_type":  "",
    "body":  null
}
```
- Live probe response sample:
```json
{
    "status":  "valid",
    "scope":  "full"
}
```

### claims

#### `GET /api/v1/claims/{user_id}`
- Operation ID: `get_user_claims_api_v1_claims__user_id__get`
- Live probe status: `500` (`not_ok`)
- Parameters:

| name | in | type | required | description |
|---|---|---|---|---|
| `user_id` | `path` | `string` | `yes` |  |
- Request body: none
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "",
    "content_type":  "",
    "body":  null
}
```

#### `POST /api/v1/claims/auto`
- Operation ID: `trigger_auto_claim_api_v1_claims_auto_post`
- Live probe status: `404` (`not_ok`)
- Parameters: none
- Request body media type: `application/json`

| field | type | required | description |
|---|---|---|---|
| `worker_id` | `string` | `yes` |  |
| `event_type` | `string` | `yes` |  |
| `amount` | `number` | `yes` |  |
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "",
    "content_type":  "application/json",
    "body":  {
                 "amount":  100,
                 "worker_id":  "11111111-1111-1111-1111-111111111111",
                 "event_type":  "WEATHER"
             }
}
```

### fraud

#### `GET /api/v1/fraud/{claim_id}`
- Operation ID: `get_fraud_report_api_v1_fraud__claim_id__get`
- Live probe status: `500` (`not_ok`)
- Parameters:

| name | in | type | required | description |
|---|---|---|---|---|
| `claim_id` | `path` | `string` | `yes` |  |
- Request body: none
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "",
    "content_type":  "",
    "body":  null
}
```

#### `POST /api/v1/fraud/check`
- Operation ID: `check_fraud_api_v1_fraud_check_post`
- Live probe status: `500` (`not_ok`)
- Parameters:

| name | in | type | required | description |
|---|---|---|---|---|
| `claim_id` | `query` | `string` | `yes` |  |
- Request body: none
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "claim_id=11111111-1111-1111-1111-111111111111",
    "content_type":  "",
    "body":  null
}
```

#### `POST /api/v1/fraud/override`
- Operation ID: `fraud_override_api_v1_fraud_override_post`
- Live probe status: `500` (`not_ok`)
- Parameters:

| name | in | type | required | description |
|---|---|---|---|---|
| `claim_id` | `query` | `string` | `yes` |  |
- Request body: none
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "claim_id=11111111-1111-1111-1111-111111111111",
    "content_type":  "",
    "body":  null
}
```

### General

#### `GET /`
- Operation ID: `root__get`
- Live probe status: `200` (`ok`)
- Parameters: none
- Request body: none
- Declared response codes: `200`
- Live probe request sample:
```json
{
    "query":  "",
    "content_type":  "",
    "body":  null
}
```
- Live probe response sample:
```json
{
    "message":  "Carbon Backend is running",
    "docs":  "/docs"
}
```

### ledger

#### `GET /api/v1/ledger/{user_id}`
- Operation ID: `get_user_ledger_api_v1_ledger__user_id__get`
- Live probe status: `200` (`ok`)
- Parameters:

| name | in | type | required | description |
|---|---|---|---|---|
| `user_id` | `path` | `string` | `yes` |  |
- Request body: none
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "",
    "content_type":  "",
    "body":  null
}
```
- Live probe response sample:
```json
{
    "id":  "76a0df23-6706-44ab-9ed0-1f3358722db3",
    "transaction_type":  "WITHDRAW",
    "amount":  -100.0,
    "created_at":  "2026-04-14T13:35:25.001716",
    "reference_id":  "11111111-1111-1111-1111-111111111111",
    "updated_at":  "2026-04-14T13:35:25.001719",
    "worker_id":  "11111111-1111-1111-1111-111111111111",
    "description":  "Insurance Payout for Claim 11111111-1111-1111-1111-111111111111"
}
```

#### `GET /api/v1/ledger/audit/{transaction_id}`
- Operation ID: `get_ledger_audit_api_v1_ledger_audit__transaction_id__get`
- Live probe status: `404` (`not_ok`)
- Parameters:

| name | in | type | required | description |
|---|---|---|---|---|
| `transaction_id` | `path` | `string` | `yes` |  |
- Request body: none
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "",
    "content_type":  "",
    "body":  null
}
```

#### `POST /api/v1/ledger/entry`
- Operation ID: `create_ledger_entry_api_v1_ledger_entry_post`
- Live probe status: `200` (`ok`)
- Parameters:

| name | in | type | required | description |
|---|---|---|---|---|
| `transaction_type` | `query` | `string` | `yes` |  |
| `amount` | `query` | `number` | `yes` |  |
| `description` | `query` | `string` | `yes` |  |
| `worker_id` | `query` | `string` | `no` |  |
| `reference_id` | `query` | `string` | `no` |  |
- Request body: none
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "transaction_type=sample\u0026amount=100\u0026description=Test%20message\u0026worker_id=11111111-1111-1111-1111-111111111111\u0026reference_id=11111111-1111-1111-1111-111111111111",
    "content_type":  "",
    "body":  null
}
```
- Live probe response sample:
```json
{
    "id":  "5ba9d72a-a93e-4985-9e98-e078c78c6855",
    "transaction_type":  "sample",
    "amount":  100.0,
    "created_at":  "2026-04-14T13:35:28.034549",
    "reference_id":  "11111111-1111-1111-1111-111111111111",
    "updated_at":  "2026-04-14T13:35:28.034554",
    "worker_id":  "11111111-1111-1111-1111-111111111111",
    "description":  "Test message"
}
```

### notify

#### `GET /api/v1/notify/{user_id}`
- Operation ID: `get_notifications_api_v1_notify__user_id__get`
- Live probe status: `200` (`ok`)
- Parameters:

| name | in | type | required | description |
|---|---|---|---|---|
| `user_id` | `path` | `string` | `yes` |  |
- Request body: none
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "",
    "content_type":  "",
    "body":  null
}
```
- Live probe response sample:
```json
{
    "updated_at":  "2026-04-14T13:35:25.016887",
    "worker_id":  "11111111-1111-1111-1111-111111111111",
    "message":  "A payout of $100.0 has been processed for your claim.",
    "status":  "SENT",
    "title":  "Payout Successful",
    "created_at":  "2026-04-14T13:35:25.016821",
    "id":  "9463bfdd-9f40-4820-8b20-92f4859ab77b",
    "type":  "PAYOUT",
    "retry_count":  0
}
```

#### `POST /api/v1/notify/retry`
- Operation ID: `retry_notification_api_v1_notify_retry_post`
- Live probe status: `200` (`ok`)
- Parameters:

| name | in | type | required | description |
|---|---|---|---|---|
| `notification_id` | `query` | `string` | `yes` |  |
- Request body: none
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "notification_id=11111111-1111-1111-1111-111111111111",
    "content_type":  "",
    "body":  null
}
```
- Live probe response sample:
```json
{
    "message":  "Retry successful for 11111111-1111-1111-1111-111111111111"
}
```

#### `POST /api/v1/notify/send`
- Operation ID: `send_manual_notification_api_v1_notify_send_post`
- Live probe status: `200` (`ok`)
- Parameters:

| name | in | type | required | description |
|---|---|---|---|---|
| `worker_id` | `query` | `string` | `yes` |  |
| `title` | `query` | `string` | `yes` |  |
| `message` | `query` | `string` | `yes` |  |
- Request body: none
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "worker_id=11111111-1111-1111-1111-111111111111\u0026title=Test%20title\u0026message=Test%20message",
    "content_type":  "",
    "body":  null
}
```
- Live probe response sample:
```json
{
    "updated_at":  "2026-04-14T13:35:26.227928",
    "worker_id":  "11111111-1111-1111-1111-111111111111",
    "message":  "Test message",
    "status":  "SENT",
    "title":  "Test title",
    "created_at":  "2026-04-14T13:35:26.227856",
    "id":  "2a48e879-cca7-4fdd-85a3-0fa031035f16",
    "type":  "SYSTEM",
    "retry_count":  0
}
```

### payout

#### `GET /api/v1/payout/{user_id}`
- Operation ID: `get_user_payouts_api_v1_payout__user_id__get`
- Live probe status: `200` (`ok`)
- Parameters:

| name | in | type | required | description |
|---|---|---|---|---|
| `user_id` | `path` | `string` | `yes` |  |
- Request body: none
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "",
    "content_type":  "",
    "body":  null
}
```
- Live probe response sample:
```json
{
    "created_at":  "2026-04-14T13:35:25.008659",
    "updated_at":  "2026-04-14T13:35:25.008668",
    "claim_id":  "11111111-1111-1111-1111-111111111111",
    "amount":  100.0,
    "status":  "PROCESSED",
    "worker_id":  "11111111-1111-1111-1111-111111111111",
    "id":  "e1fffd94-9d14-4946-88dc-af385a7e0313",
    "idempotency_key":  "PAY-11111111-1111-1111-1111-111111111111"
}
```

#### `POST /api/v1/payout/process`
- Operation ID: `process_payout_api_v1_payout_process_post`
- Live probe status: `200` (`ok`)
- Parameters:

| name | in | type | required | description |
|---|---|---|---|---|
| `claim_id` | `query` | `string` | `yes` |  |
| `worker_id` | `query` | `string` | `yes` |  |
| `amount` | `query` | `number` | `yes` |  |
- Request body: none
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "claim_id=11111111-1111-1111-1111-111111111111\u0026worker_id=11111111-1111-1111-1111-111111111111\u0026amount=100",
    "content_type":  "",
    "body":  null
}
```
- Live probe response sample:
```json
{

}
```

#### `POST /api/v1/payout/retry`
- Operation ID: `retry_payout_api_v1_payout_retry_post`
- Live probe status: `200` (`ok`)
- Parameters:

| name | in | type | required | description |
|---|---|---|---|---|
| `payout_id` | `query` | `string` | `yes` |  |
- Request body: none
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "payout_id=11111111-1111-1111-1111-111111111111",
    "content_type":  "",
    "body":  null
}
```
- Live probe response sample:
```json
{
    "message":  "Retry initiated for payout 11111111-1111-1111-1111-111111111111"
}
```

### policy

#### `GET /api/v1/policy/{user_id}`
- Operation ID: `get_policy_api_v1_policy__user_id__get`
- Live probe status: `404` (`not_ok`)
- Parameters:

| name | in | type | required | description |
|---|---|---|---|---|
| `user_id` | `path` | `string` | `yes` |  |
- Request body: none
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "",
    "content_type":  "",
    "body":  null
}
```

#### `POST /api/v1/policy/create`
- Operation ID: `create_policy_api_v1_policy_create_post`
- Live probe status: `404` (`not_ok`)
- Parameters: none
- Request body media type: `application/json`

| field | type | required | description |
|---|---|---|---|
| `worker_id` | `string` | `yes` |  |
| `premium_amount` | `number` | `yes` |  |
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "",
    "content_type":  "application/json",
    "body":  {
                 "worker_id":  "11111111-1111-1111-1111-111111111111",
                 "premium_amount":  100
             }
}
```

#### `POST /api/v1/policy/opt-in`
- Operation ID: `opt_in_api_v1_policy_opt_in_post`
- Live probe status: `404` (`not_ok`)
- Parameters: none
- Request body media type: `application/json`

| field | type | required | description |
|---|---|---|---|
| `worker_id` | `string` | `yes` |  |
| `premium_amount` | `number` | `yes` |  |
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "",
    "content_type":  "application/json",
    "body":  {
                 "worker_id":  "11111111-1111-1111-1111-111111111111",
                 "premium_amount":  100
             }
}
```

#### `POST /api/v1/policy/opt-out`
- Operation ID: `opt_out_api_v1_policy_opt_out_post`
- Live probe status: `404` (`not_ok`)
- Parameters:

| name | in | type | required | description |
|---|---|---|---|---|
| `worker_id` | `query` | `string` | `yes` |  |
- Request body: none
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "worker_id=11111111-1111-1111-1111-111111111111",
    "content_type":  "",
    "body":  null
}
```

#### `POST /api/v1/policy/validate`
- Operation ID: `validate_policy_api_v1_policy_validate_post`
- Live probe status: `200` (`ok`)
- Parameters:

| name | in | type | required | description |
|---|---|---|---|---|
| `worker_id` | `query` | `string` | `yes` |  |
- Request body: none
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "worker_id=11111111-1111-1111-1111-111111111111",
    "content_type":  "",
    "body":  null
}
```
- Live probe response sample:
```json
{
    "is_valid":  false,
    "reason":  "No active policy found"
}
```

### pool

#### `GET /api/v1/pool/ledger/{user_id}`
- Operation ID: `get_user_ledger_api_v1_pool_ledger__user_id__get`
- Live probe status: `200` (`ok`)
- Parameters:

| name | in | type | required | description |
|---|---|---|---|---|
| `user_id` | `path` | `string` | `yes` |  |
- Request body: none
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "",
    "content_type":  "",
    "body":  null
}
```
- Live probe response sample:
```json
"[]"
```

#### `GET /api/v1/pool/status`
- Operation ID: `get_pool_status_api_v1_pool_status_get`
- Live probe status: `200` (`ok`)
- Parameters: none
- Request body: none
- Declared response codes: `200`
- Live probe request sample:
```json
{
    "query":  "",
    "content_type":  "",
    "body":  null
}
```
- Live probe response sample:
```json
{
    "total_balance":  550.0,
    "last_audit_date":  "2026-04-14T08:48:40.222350"
}
```

### pricing

#### `POST /api/v1/pricing/calculate`
- Operation ID: `calculate_pricing_api_v1_pricing_calculate_post`
- Live probe status: `200` (`ok`)
- Parameters: none
- Request body media type: `application/json`

| field | type | required | description |
|---|---|---|---|
| `base_amount` | `number` | `yes` |  |
| `risk_score` | `number` | `no` |  |
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "",
    "content_type":  "application/json",
    "body":  {
                 "base_amount":  100
             }
}
```
- Live probe response sample:
```json
{
    "premium_amount":  125.0,
    "base_amount":  100.0,
    "risk_score":  0.5
}
```

#### `POST /api/v1/pricing/recalculate`
- Operation ID: `recalculate_pricing_api_v1_pricing_recalculate_post`
- Live probe status: `200` (`ok`)
- Parameters:

| name | in | type | required | description |
|---|---|---|---|---|
| `worker_id` | `query` | `string` | `yes` |  |
- Request body: none
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "worker_id=11111111-1111-1111-1111-111111111111",
    "content_type":  "",
    "body":  null
}
```
- Live probe response sample:
```json
{
    "worker_id":  "11111111-1111-1111-1111-111111111111",
    "new_premium":  59.58
}
```

### risk

#### `GET /api/v1/risk/drift`
- Operation ID: `check_risk_drift_api_v1_risk_drift_get`
- Live probe status: `200` (`ok`)
- Parameters: none
- Request body: none
- Declared response codes: `200`
- Live probe request sample:
```json
{
    "query":  "",
    "content_type":  "",
    "body":  null
}
```
- Live probe response sample:
```json
{
    "status":  "STABLE",
    "drift_score":  0.02,
    "last_check":  "2026-04-14T13:35:24.392391"
}
```

#### `POST /api/v1/risk/evaluate`
- Operation ID: `evaluate_risk_api_v1_risk_evaluate_post`
- Live probe status: `200` (`ok`)
- Parameters:

| name | in | type | required | description |
|---|---|---|---|---|
| `worker_id` | `query` | `string` | `yes` |  |
- Request body: none
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "worker_id=11111111-1111-1111-1111-111111111111",
    "content_type":  "",
    "body":  null
}
```
- Live probe response sample:
```json
{
    "risk_score":  0.5153883630193948,
    "risk_category":  "MEDIUM",
    "premium_multiplier":  1.1,
    "confidence":  0.92,
    "prediction_id":  "pred_4521f984",
    "factors":  [
                    {
                        "factor":  "disruption_frequency",
                        "weight":  0.4,
                        "impact":  0.20615534520775794
                    },
                    {
                        "factor":  "historical_volatility",
                        "weight":  0.3,
                        "impact":  0.05
                    },
                    {
                        "factor":  "location_risk_index",
                        "weight":  0.3,
                        "impact":  0.051538836301939485
                    }
                ]
}
```

#### `POST /api/v1/risk/feedback`
- Operation ID: `submit_risk_feedback_api_v1_risk_feedback_post`
- Live probe status: `200` (`ok`)
- Parameters:

| name | in | type | required | description |
|---|---|---|---|---|
| `prediction_id` | `query` | `string` | `yes` |  |
| `is_accurate` | `query` | `boolean` | `yes` |  |
- Request body: none
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "prediction_id=11111111-1111-1111-1111-111111111111\u0026is_accurate=True",
    "content_type":  "",
    "body":  null
}
```
- Live probe response sample:
```json
{
    "message":  "Feedback recorded",
    "prediction_id":  "11111111-1111-1111-1111-111111111111"
}
```

#### `GET /api/v1/risk/health`
- Operation ID: `risk_service_health_api_v1_risk_health_get`
- Live probe status: `200` (`ok`)
- Parameters: none
- Request body: none
- Declared response codes: `200`
- Live probe request sample:
```json
{
    "query":  "",
    "content_type":  "",
    "body":  null
}
```
- Live probe response sample:
```json
{
    "status":  "HEALTHY",
    "model_version":  "v1.0.4"
}
```

### trigger

#### `GET /api/v1/trigger/active`
- Operation ID: `get_active_disruptions_api_v1_trigger_active_get`
- Live probe status: `200` (`ok`)
- Parameters: none
- Request body: none
- Declared response codes: `200`
- Live probe request sample:
```json
{
    "query":  "",
    "content_type":  "",
    "body":  null
}
```
- Live probe response sample:
```json
[
    {
        "id":  "d1",
        "type":  "WEATHER",
        "zone":  "San Francisco",
        "active":  true
    },
    {
        "id":  "d2",
        "type":  "TRAFFIC",
        "zone":  "London",
        "active":  true
    }
]
```

#### `POST /api/v1/trigger/mock`
- Operation ID: `mock_disruption_api_v1_trigger_mock_post`
- Live probe status: `500` (`not_ok`)
- Parameters:

| name | in | type | required | description |
|---|---|---|---|---|
| `event_type` | `query` | `string` | `yes` |  |
- Request body: none
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "event_type=WEATHER",
    "content_type":  "",
    "body":  null
}
```

#### `POST /api/v1/trigger/stop`
- Operation ID: `stop_simulation_api_v1_trigger_stop_post`
- Live probe status: `200` (`ok`)
- Parameters: none
- Request body: none
- Declared response codes: `200`
- Live probe request sample:
```json
{
    "query":  "",
    "content_type":  "",
    "body":  null
}
```
- Live probe response sample:
```json
{
    "message":  "All simulations stopped"
}
```

### workers

#### `GET /api/v1/workers/{user_id}`
- Operation ID: `get_worker_api_v1_workers__user_id__get`
- Live probe status: `404` (`not_ok`)
- Parameters:

| name | in | type | required | description |
|---|---|---|---|---|
| `user_id` | `path` | `string` | `yes` |  |
- Request body: none
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "",
    "content_type":  "",
    "body":  null
}
```

#### `PUT /api/v1/workers/{user_id}`
- Operation ID: `update_worker_api_v1_workers__user_id__put`
- Live probe status: `404` (`not_ok`)
- Parameters:

| name | in | type | required | description |
|---|---|---|---|---|
| `user_id` | `path` | `string` | `yes` |  |
- Request body media type: `application/json`

| field | type | required | description |
|---|---|---|---|
| `phone` | `string` | `yes` |  |
| `full_name` | `object` | `no` |  |
| `email` | `object` | `no` |  |
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "",
    "content_type":  "application/json",
    "body":  {
                 "phone":  "9876543210"
             }
}
```

#### `POST /api/v1/workers/profile`
- Operation ID: `create_profile_api_v1_workers_profile_post`
- Live probe status: `200` (`ok`)
- Parameters: none
- Request body media type: `application/json`

| field | type | required | description |
|---|---|---|---|
| `phone` | `string` | `yes` |  |
| `full_name` | `object` | `no` |  |
| `email` | `object` | `no` |  |
- Declared response codes: `200, 422`
- Live probe request sample:
```json
{
    "query":  "",
    "content_type":  "application/json",
    "body":  {
                 "phone":  "9876543210"
             }
}
```
- Live probe response sample:
```json
{
    "phone":  "9876543210",
    "full_name":  "Rafi",
    "email":  "rafi@example.com",
    "id":  "1f4029bd-b5b8-4282-98d7-e37ee94721d1",
    "is_active":  true,
    "is_verified":  true,
    "balance":  0.0,
    "created_at":  "2026-04-14T06:58:07.821684"
}
```

## Production-Grade Improvement Plan
### 1) Security and Access Control (Critical)
- Enforce JWT auth on all user-scoped and financial routes using mandatory bearer dependency.
- Add object-level authorization checks (`user_id` in path must match token subject unless admin role).
- Make `POST /auth/logout` invalidate refresh/access token pair in persistent token store.
- Add auth integration tests for unauthenticated (`401`) and forbidden (`403`) paths.

### 2) Claims/Trigger/Fraud Stability (Critical)
- Fix backend `500` paths by wrapping service edges in typed domain exceptions and returning deterministic `4xx/5xx` models.
- Add idempotency key support for claim creation and trigger simulation endpoints.
- Add circuit breakers/retries around external dependencies used by trigger and fraud layers.
- Add transaction boundaries for claim -> payout -> ledger side effects.

### 3) Contract Consistency (High)
- Normalize collection responses to one envelope format, e.g. `{ "items": [], "count": n, "next_cursor": null }`.
- Remove shape drift (`{}` vs `{ value:[], Count:n }` vs object) to avoid brittle frontend parsers.
- Add strict request/response Pydantic models for every endpoint and forbid extra fields.
- Version API with explicit deprecation headers and migration docs for route changes.

### 4) Observability and Operability (High)
- Add structured logs with correlation IDs (`X-Request-ID`) propagated across all services.
- Publish SLOs and metrics: error rate, p95 latency, payout success ratio, claim decision latency.
- Add readiness/liveness probes with dependency checks (DB, queue, model service).
- Emit audit logs for policy changes, payouts, overrides, and auth events.

### 5) Data Integrity and Financial Safety (High)
- Enforce ledger double-entry invariants and pool balance constraints at DB transaction level.
- Use unique idempotency constraints for payout processing keyed by claim/payout id.
- Add reconciliation jobs (pool, ledger, payouts) with anomaly alerts.
- Store monetary fields as fixed-point decimals with explicit currency.

### 6) Test Strategy (High)
- Contract tests generated from OpenAPI for every operation and status code.
- End-to-end scenario tests: register -> opt-in -> trigger -> claim -> payout -> ledger -> notify.
- Negative tests for authz boundaries and malformed payloads.
- Load tests for dashboard/timeseries and trigger fan-out paths.

### 7) Developer Experience (Medium)
- Keep OpenAPI examples in sync with production responses; generate SDKs for Flutter/backend tooling.
- Add `make`/scripted smoke runner to execute the same sweep in CI/CD and gate deployment.
- Document auth lifecycle clearly (otp -> verify/login -> refresh -> logout semantics).

