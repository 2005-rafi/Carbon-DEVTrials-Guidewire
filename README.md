# Carbon — Parametric Income Disruption Insurance
### Guidewire DEVTrails 2026 · Phase 3 Submission · Soar Phase


Carbon is an AI-enabled parametric microinsurance platform purpose-built for **Food Delivery Partners** across India. When an uncontrollable external disruption — a flash flood, a declared curfew, a city-wide platform outage — halts their ability to earn, Carbon automatically detects it, validates it, and transfers the lost wages directly to their UPI account. No claim forms. No adjusters. No waiting.

---

## 📋 Table of Contents

1. [The Problem](#1-the-problem)
2. [Persona & Scenario Workflow](#2-persona--scenario-workflow)
3. [Weekly Premium Model](#3-weekly-premium-model)
4. [Parametric Triggers](#4-parametric-triggers)
5. [System Architecture — Microservices & Event-Driven Design](#5-system-architecture--microservices--event-driven-design)
6. [AI & ML Integration](#6-ai--ml-integration)
7. [🚨 Market Crash Response — Adversarial Defense & Anti-Spoofing Strategy](#7--market-crash-response--adversarial-defense--anti-spoofing-strategy)
8. [Platform Choice: Why Mobile?](#8-platform-choice-why-mobile)
9. [Coverage Scope & Exclusions](#9-coverage-scope--exclusions)
10. [Insurance Product Policy Summary](#10-insurance-product-policy-summary)
11. [Tech Stack](#11-tech-stack)
12. [Phase 2 — What We Built](#13-phase-2--what-we-built)

---

## 1. The Problem

India's food delivery ecosystem runs on the backs of delivery partners. An estimated 5–7 million workers operate across food delivery platforms in a purely gig-based model with no guaranteed income, no sick pay, and no protection from forces outside their control.

When a sudden flash flood inundates a zone, when a government-declared curfew shuts down movement, or when a platform-wide outage kills order flow for hours — these workers lose real money immediately. Research indicates such disruptions can erase **20–30% of monthly earnings** with zero recourse.

**Traditional insurance has failed this segment entirely:**
- Monthly or annual premiums don't align with weekly cash cycles
- Manual claims processes take days or weeks — useless for someone who needs money tonight
- No product exists that covers pure income loss from weather/social disruptions for gig workers

**Carbon exists to close this gap.**

---

## 2. Persona & Scenario Workflow

### Target Persona
**Food Delivery Partners** operating across food delivery platforms in Tier 1 & Tier 2 Indian cities. Full-time riders earning ₹8,000–₹18,000/week and part-time riders earning ₹3,000–₹7,000/week.

### The Core Scenario

> Ravi is a full-time food delivery partner in Chennai. It's a Wednesday evening — peak hour. He picks up an order from a restaurant (Point Y) heading to a customer (Point Z). Midway, a flash flood from unseasonal rainfall inundates the route. Roads are impassable. He marks himself online but cannot move. He loses 4 hours of earning time.

**Without Carbon:** Ravi loses ₹600–₹800 in wages with no recourse.

**With Carbon:** Here is what happens silently in the background:

```
[1] PASSIVE MONITORING
    Carbon app runs in background during active shift.
    GPS & accelerometer track movement state.

[2] ROUTE INTELLIGENCE
    Carbon detects active delivery route bounding box
    from intercepted platform push notification.
    Zone: Chennai South → Anna Nagar corridor

[3] TRIGGER CHECK (< 5 minutes)
    Open-Meteo API: Rainfall = 68mm/hr (threshold: ≥50mm/hr ✅)
    TomTom API: Status = "Road Closed" on route ✅
    IMD Feed: No active all-clear signal ✅
    Ravi's platform status: Online, zero orders assigned ✅

[4] AUTOMATED CLAIM INITIATED
    Event classified: STANDARD (duration < 6 hours)
    Fraud engine clears Ravi (GPS authentic, earnings history normal)
    Policy engine confirms: premium paid ✅, waiting period elapsed ✅,
    activity threshold (3+ delivery days this week) ✅

[5] PAYOUT COMPUTED & SENT (within 2–4 hours)
    IDI = ₹10,500 ÷ 7 = ₹1,500/day
    Coverage Rate (Medium Risk Zone): 70%
    Disruption hours: 4hrs → 0.5 disruption days credited
    Payout = ₹1,500 × 70% × 0.5 = ₹525 → UPI transfer initiated

[6] RAVI NOTIFIED
    SMS + in-app: "₹525 credited to your UPI for the Chennai flood
    disruption. Claim Ref: CRB-20260318-00412."
```

Ravi never filed a claim. Carbon did it for him.

---

## 3. Weekly Premium Model

Gig workers operate on a week-to-week cash cycle. Annual or monthly premiums are structurally incompatible with this reality. Carbon's premium is computed fresh every week.

### Premium Formula

```
Weekly Premium = Insured Weekly Income (IWI) × Risk Zone Rate × Stabilization Factor (SF)

+ GST @ 18% (CGST 9% + SGST 9%)
```

**Where:**
- **IWI** = Sum of gross platform earnings in the last 7 days (sourced via platform OAuth API)
- **Risk Zone Rate** = Determined by the worker's primary operating zone (reviewed quarterly):

| Zone Code | Risk Level | Premium Rate | Coverage Rate |
|-----------|-----------|-------------|--------------|
| LR-1 | Low | 0.50% of IWI | 60% of IDI |
| MR-2 | Medium | 1.00% of IWI | 70% of IDI |
| HR-3 | High | 2.00% of IWI | 80% of IDI |

- **Stabilization Factor (SF)** = A temporary multiplier (max 1.15×) applied in early pool cycles to ensure reserve liquidity. Reduces to exactly 1.0 once the pool achieves its target 20% reserve ratio.

### Illustrative Weekly Premiums

| Rider Type | Weekly Income | Zone | Rate | SF | Base Premium | GST | Total |
|-----------|--------------|------|------|----|-------------|-----|-------|
| Part-time / Low Risk | ₹5,250 | LR-1 | 0.50% | 1.05 | ₹27.56 | ₹4.96 | ₹32.52 |
| Full-time / Medium Risk | ₹10,500 | MR-2 | 1.00% | 1.00 | ₹105.00 | ₹18.90 | ₹123.90 |
| High-earner / High Risk | ₹17,500 | HR-3 | 2.00% | 1.00 | ₹350.00 | ₹63.00 | ₹413.00 |

### Key Design Decisions
- **Activity Scaling:** Premium is proportional to earnings — part-timers pay proportionally less than full-timers
- **Auto-Deduction:** Weekly premium auto-debited every Monday via UPI Autopay (NACH mandate)
- **2-Day Waiting Period:** Coverage activates 48 hours after payment — prevents adverse selection
- **Lapse & Re-activation:** Failed payment = immediate lapse; re-activation requires fresh 2-day waiting period

### Payout Formula
```
IDI (Insured Daily Income) = Weekly Income ÷ 7
Daily Payout              = IDI × Coverage Rate (60% / 70% / 80%)
Weekly Payout             = Daily Payout × Number of verified disruption days
```

---

## 4. Parametric Triggers

Carbon removes the claims adjuster entirely by using real-time, verifiable API data as the sole arbiter of payout decisions.

### Trigger Category 1 — Environmental (Weather)

| Disruption | Standard Threshold | Severe Threshold | Data Source |
|-----------|-------------------|-----------------|------------|
| Rainfall / Flash Flood | ≥ 50mm/hr for 3+ hours | ≥ 100mm/hr or IMD Red Alert | Open-Meteo API, IMD OpenData |
| Heatwave | ≥ 45°C sustained 3+ hours | ≥ 47°C or state advisory | IMD API |
| Severe Air Pollution | AQI ≥ 301 (PM2.5 basis) | AQI ≥ 401 + work stoppage order | CPCB AQI API |
| Flood Declaration | Local ward/zone flooding | District-level disaster declaration | NDMA / State DM Portal |

### Trigger Category 2 — Social / Governmental

| Disruption | Standard Threshold | Severe Threshold | Data Source |
|-----------|-------------------|-----------------|------------|
| Bandh / Curfew | Notified zone bandh / blockage | City/state-wide curfew or emergency | District Admin Portal / News API |
| Road Closure | Official road blockage on active route | Multi-route / zone-wide closure | TomTom Traffic API |

### Trigger Category 3 — Platform / Market

| Disruption | Standard Threshold | Severe Threshold | Data Source |
|-----------|-------------------|-----------------|------------|
| Platform Outage | Platform API down ≥ 3 hours while driver online | Platform down ≥ 6 hours | Platform Status API |
| Order Volume Crash | > 50% drop vs. 7-day zone average | > 70% drop across zone | Platform API (aggregated) |

### Event Escalation Model
Events start at **Standard** tier (3–4 day payout cap/week). If a Standard event exceeds 6 continuous hours or spreads to 3+ adjacent zones, it auto-escalates to **Severe** (up to 7-day full coverage, no cap). Payouts begin immediately at Standard — a retroactive top-up is applied if escalated.

### Crowdsourced SOS Trigger (API Fallback)
When primary APIs are unavailable, workers submit a geo-tagged live camera photo. Carbon requires 3+ independent reports within a 500m radius within 30 minutes. Each submission is perceptual-hashed — duplicate and screen-photographed images are silently rejected.

---

## 5. System Architecture — Microservices & Event-Driven Design

Carbon is built as a **production-grade, event-driven microservices system**. Each service is independently deployable, loosely coupled via an event bus, and owns a single responsibility.

### End-to-End Automated Pipeline

```
External Disruption
        │
        ▼
  Trigger Service ──────────────► Event Bus (RabbitMQ)
                                        │
                    ┌───────────────────┼───────────────────┐
                    ▼                   ▼                   ▼
             Claims Engine       Notification        Analytics
                    │            Service             Service
                    ▼
          Policy Validation
                    │
                    ▼
           AI Risk Scoring
                    │
                    ▼
          Fraud Detection
                    │
                    ▼
         Decision Engine
                    │
            ┌───────┴───────┐
            ▼               ▼
        Approved         Rejected
            │
            ▼
      Payout Service
            │
            ▼
    UPI Transfer + SMS Notification
```

### Microservices Breakdown

**1. Identity & Worker Service**
- JWT-based authentication
- Worker onboarding and KYC
- Profile management (zone classification, income history)
- Foundation for all downstream services

**2. Policy & Pricing Service**
- Weekly policy creation and renewal
- Dynamic premium calculation engine
- Coverage logic and waiting period enforcement
- Policy status management (active / lapsed / cancelled)

**3. AI Risk Service**
- Real-time risk scoring (0.0 → 1.0 scale)
- Risk category output: LOW / MEDIUM / HIGH
- Premium multiplier generation
- Feeds into both pricing and claims decision engines

**4. Trigger Service**
- Continuously polls weather, traffic, and platform APIs
- Converts detected disruptions into structured events
- Publishes events to the RabbitMQ event bus
- Handles threshold validation before event publication

**5. Event Bus (RabbitMQ)**
- Decouples all services — no service calls another directly
- Handles async communication across the entire pipeline
- Enables horizontal scaling of individual services
- Dead-letter queue for failed event processing

**6. Claims & Decision Engine (Core Orchestrator)**
- Receives disruption events from the event bus
- Auto-creates claim records
- Orchestrates: policy validation → AI scoring → fraud check → decision
- Approves or rejects with full audit trail

**7. Fraud Detection Service**
- GPS spoof detection via kinematic fingerprinting
- Duplicate claim prevention (SHA-256 hash uniqueness)
- Behavioral anomaly analysis
- Earnings inflation detection
- Returns fraud confidence score to claims engine

**8. Payout Service**
- Executes approved payouts via UPI / mock payment gateway
- Maintains an immutable financial ledger
- Idempotency keys prevent double-payment
- Integrated with Razorpay sandbox

**9. Notification Service**
- Decoupled notification layer (SMS, push, in-app)
- Triggered by events from the bus — not by direct service calls
- Sends claim initiation, approval, payout, and rejection alerts

**10. Analytics Service**
- Aggregates system-wide data for admin dashboard
- KPIs: active policies, total payouts, fraud detected, zone-wise risk
- Loss ratio monitoring and trend analysis

### API Contract System

| Endpoint | Service | Purpose |
|----------|---------|---------|
| `POST /auth/register` | Identity | Worker registration |
| `POST /auth/login` | Identity | JWT token issuance |
| `POST /policy/create` | Policy | Weekly policy creation |
| `GET /policy/status` | Policy | Active coverage check |
| `POST /claims/auto` | Claims Engine | Auto-initiate claim |
| `GET /claims/status` | Claims Engine | Claim status lookup |
| `POST /payout/process` | Payout | Execute payout |
| `GET /analytics/dashboard` | Analytics | Admin KPI dashboard |

---

## 6. AI & ML Integration

### Machine Learning — The Data Crunchers

**1. Dynamic Weekly Pricing Engine (XGBoost)**
Adjusts premium based on hyper-local historical risk signals per zone — disruption frequency, seasonal patterns, and historical loss ratios.

**2. Kinematic Anomaly Detection (LSTM)**
Continuously analyzes GPS + accelerometer + gyroscope time-series data. Synthetic GPS movement produces "too smooth" trajectories with abnormal accelerometer silence — the model flags kinematically impossible patterns in real time.

**3. Earnings Baseline Model**
Rolling 30-day median per worker detects IDI inflation. If IWI spikes >30% above the 30-day median, IDI is capped at the verified platform figure.

### AI — The Real-Time Gatekeepers

**1. Perceptual Image Hashing** — dHash + pHash on every SOS photo submission. Hash distance < 10 from recent zone submissions = auto-rejected duplicate.

**2. Moiré Pattern Detection (CNN)** — Detects photos taken of digital screens. Live camera capture enforced at OS level; CNN provides a second line of defense.

**3. Real-Time Fraud Scoring Pipeline**

```
FRAUD SIGNAL              DETECTION METHOD                    OUTCOME
─────────────────────────────────────────────────────────────────────
GPS Spoofing           Cell-tower cross-check + LSTM           Claim void; account flagged
Fake Weather Claim     Requires ≥10 zone corroborations        Suspended pending validation
Duplicate SOS Photo    SHA-256 + pHash similarity              Silently rejected
Screen Photo           Moiré CNN                               Rejected; worker warned
Inactive During Event  Platform API: zero orders received      Payout adjusted/rejected
Earnings Inflation     IDI vs. 30-day platform median          IDI capped at verified figure
```

---

## 7. 🚨 Market Crash Response — Adversarial Defense & Anti-Spoofing Strategy

> **Scenario:** A coordinated fraud ring of 500 delivery partners using fake GPS signals to claim payouts during fabricated disruptions. Simple GPS verification is dead. The liquidity pool is under attack.

### The Attacker's Playbook

Three primary attack vectors:
1. **GPS Spoofing at Scale** — Mock location apps placing fraudsters "on route" during genuine disruptions
2. **Synthetic Disruption Farming** — Coordinating SOS reports to artificially trigger Red Zones
3. **Earnings Inflation** — Inflating IWI in days before a forecast storm to maximize payout

Carbon's defense is built on one core principle: **It is extremely difficult to fake multiple independent, physics-consistent signals simultaneously.**

### Layer 1 — Kinematic Consistency Engine

A genuine stranded rider shows:
- Accelerometer: micro-vibrations consistent with idling two-wheeler engine (3–8 Hz)
- Gyroscope: small-angle oscillations consistent with vehicle in idle

A GPS spoofer sitting at home shows:
- Accelerometer: **silence** — no road vibration, no engine idle ❌
- Gyroscope: **flat** — no two-wheeler micro-corrections ❌

**Secondary:** Cell tower triangulation cross-referenced against spoofed GPS coordinates catches location mismatches.

### Layer 2 — Zone Corroboration Requirement

Environmental triggers require corroboration from **≥10 workers in the zone**. Corroboration is strict — each worker must show an independent kinematic fingerprint, be spatially distributed (not clustered at one GPS point), and reports must be temporally staggered. Most importantly: if Open-Meteo shows 2mm rainfall but 500 workers claim a flood — the trigger fails. No one can manufacture an API-verified weather event.

### Layer 3 — Behavioral Timeline Analysis

Workers enrolling 48–72 hours before a forecast storm are flagged as adversarial enrollment candidates and subject to stricter kinematic thresholds on their first claim. Workers with 3+ such instances are permanently barred. IWI spikes >30% above 30-day median result in IDI being capped at the median figure.

### Layer 4 — SOS Photo Integrity

| Attack | Detection | Response |
|--------|-----------|----------|
| Same photo submitted multiple times | pHash similarity check | Silently rejected |
| Photo of a screen showing fake flood | Moiré pattern CNN | Rejected; worker warned |
| Gallery image instead of live camera | OS-level enforcement | Blocked before submission |
| Coordinated identical images | Cross-account hash clustering | Zone suspended; fraud investigation |

### Layer 5 — Pool-Level Anomaly Monitoring

Claim rate > 2× historical zone average pauses the event for API re-validation. Loss ratio trending above 65% triggers an actuarial alert. A reinsurance layer activates for catastrophic events exceeding the pool's self-retention limit.

### How Carbon Tells the Faker from the Genuinely Stranded Worker

```
SIGNAL                        GENUINE WORKER           SPOOFER / FRAUD
──────────────────────────────────────────────────────────────────────
GPS position                  Matches zone             Matches zone (spoofed)
Cell tower position           Matches GPS ✅           Contradicts GPS ❌
Accelerometer signature       Idle engine vibration ✅  Silence / sitting ❌
Gyroscope                     Small corrections ✅      Flat ❌
Platform status               Online, no orders ✅      Online, no orders (same)
Spatial distribution          Distributed in zone      Clustered at one point ❌
Zone corroboration (≥10)      Diverse fingerprints ✅   Homogeneous fingerprints ❌
Primary API (weather/traffic) Confirms event ✅         Confirms event ✅
Enrollment timing             Normal history           Recent pre-storm enrollment ❌
IWI vs. 30-day median         Normal ✅                Inflated ❌
```

The fraud engine requires a **weighted confidence score** across all signals. Beating one signal does not beat the system.

### No Honest Workers Punished
- **Recall over precision** — wrongly denying a genuine claim costs more than paying a borderline one
- **Transparent flagging** — worker notified immediately with reference ID and 48-hour resolution commitment
- **Human review escalation** — any worker can request human review within 30 days
- **Zone-level investigations** do not auto-deny individual workers — each claim is reviewed independently

---

## 8. Platform Choice: Why Mobile?

Carbon is built as a **Flutter (Dart) mobile application**, not a web platform. This is a functional necessity, not a preference.

| Requirement | Why Mobile is the Only Option |
|-------------|-------------------------------|
| Background GPS tracking | Web browsers cannot run persistent background location processes |
| Accelerometer + Gyroscope | Browser motion sensor APIs are unreliable and iOS-restricted |
| Push notification interception | Extracting route data from platform notifications requires native OS integration |
| Live Camera enforcement | Forcing live-capture-only for SOS photos requires native camera API control |
| UPI deep-linking | Native deep-link integration required for UPI Autopay mandate setup |
| Worker demographic | Delivery partners are exclusively mobile-first during shifts |

---

## 9. Coverage Scope & Exclusions

Carbon covers **INCOME LOSS ONLY** arising from verified external disruptions.

### What Carbon Covers ✅
- Income lost during verified environmental disruptions (rainfall, flood, heatwave, severe pollution)
- Income lost during verified social/governmental disruptions (curfew, declared bandh, official road closures)
- Income lost during verified platform/market disruptions (extended outages, severe order volume crashes)

### What Carbon Strictly Excludes ❌
- Medical bills, illness, hospitalisation, injury, accident, disability, or death
- Vehicle breakdown, vehicle damage, fuel costs, or any repair/maintenance expense
- Voluntary inactivity, personal rest days, or self-imposed work stoppage
- Normal or seasonal demand fluctuation or ordinary market slowdown
- Personal disputes or domestic emergencies
- Events occurring during the mandatory 2-day waiting period
- Weeks in which the minimum 3-active-delivery-day threshold is not met
- Any fraudulent activity or wilful misrepresentation

---

## 10. Insurance Product Policy Summary

Carbon's product policy is a prototype document defining the full coverage architecture, premium mechanics, payout logic, and fraud provisions.

| Parameter | Details |
|-----------|---------|
| Product Type | Parametric Microinsurance — Income Disruption Cover |
| Target Beneficiary | Food Delivery Partners |
| Coverage Basis | Loss of Income ONLY due to verified external disruptions |
| Premium Cycle | Weekly — aligned to gig worker earnings cycle |
| Payout Mechanism | Fully automated parametric trigger — zero manual claims |
| Payout Rate | 60%–80% of Insured Daily Income (zone-dependent) |
| Waiting Period | 2 days from premium payment date |
| Minimum Activity | 3 active delivery days in preceding 7-day period |
| Payout Timeline | 2–4 hours from trigger confirmation |

Full policy wording did by carbon: https://drive.google.com/drive/folders/15r2QkbAI4T_a5V2oRaSSNYTo30nzutsc

---

## 11. Tech Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| Mobile Frontend | Flutter (Dart) | Cross-platform, hardware sensor access, background processes |
| Backend API | FastAPI (Python 3.11) | Async, low-latency — ideal for real-time trigger monitoring |
| Message Broker | RabbitMQ | Event-driven decoupling across all microservices |
| Database | PostgreSQL | ACID compliance for financial ledger, policy, and claim records |
| ML Model Serving | FastAPI + ONNX Runtime | Lightweight inference without heavy ML framework overhead |
| Containerization | Docker | Each microservice runs independently |
| Web Demo | HTML / CSS / JavaScript (AWS) | Admin dashboard and demo interface |

### External Integrations

| Integration | Purpose | Status |
|-------------|---------|--------|
| Open-Meteo API | Real-time rainfall, temperature, weather | Live (free tier) |
| IMD OpenData API | Official flood / weather declarations | Live |
| CPCB AQI API | Real-time Air Quality Index | Live |
| TomTom Traffic API | Road closure detection, route blockages | Live (free tier) |
| Food Delivery Platform API | Order volume, platform uptime, driver activity | Simulated |
| Razorpay UPI Sandbox | Premium collection, payout disbursement | Sandbox |
| DigiLocker / CKYC | KYC verification at onboarding | Simulated |

---


## 12. Phase 2 — What We Built

Phase 2 theme: **"Protect Your Worker"** — moving from ideation to a fully functional, automated insurance backend.

### ✅ Phase 2 Deliverables Completed

| Deliverable | Status |
|-------------|--------|
| Worker Registration & Authentication (JWT) | ✅ Complete |
| Insurance Policy Management | ✅ Complete |
| Dynamic Premium Calculation Engine | ✅ Complete |
| Claims Auto-initiation & Management | ✅ Complete |
| AI Risk Scoring Service | ✅ Complete |
| Fraud Detection Service | ✅ Complete |
| Payout Service (Razorpay Sandbox) | ✅ Complete |
| Event Bus Integration (RabbitMQ) | ✅ Complete |
| Notification Service | ✅ Complete |
| Admin Analytics Dashboard | ✅ Complete |

### What Was Built vs. What Is Simulated

| Component | Built | Simulated |
|-----------|-------|-----------|
| Weather trigger (Open-Meteo) | ✅ Live API | — |
| Traffic trigger (TomTom) | ✅ Live API | — |
| ML risk scoring | ✅ Integrated | — |
| GPS fraud detection | ✅ Integrated | — |
| Platform activity data | — | ✅ Mock API |
| UPI Payout | — | ✅ Razorpay Sandbox |
| KYC (DigiLocker) | — | ✅ Simulated |

### Architecture Achievement

Carbon is not just an app — it is a **distributed insurance operating system**:
- 10 independent microservices, each with a single responsibility
- Fully event-driven via RabbitMQ — no service calls another directly
- Complete automated claim lifecycle: disruption detected → claim created → validated → fraud checked → approved → paid → notified → logged
- Zero human intervention required at any step


