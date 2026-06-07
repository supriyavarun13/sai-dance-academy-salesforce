# Sai Dance Academy — Salesforce Experience Cloud Platform

A full-stack Salesforce build for a fictional dance academy: a public website where visitors discover classes, enroll and pay online, register for events, get AI-assisted support, and submit enquiries — backed by a complete service, payments, and analytics operation for administrators.

Built end-to-end on a single Salesforce org spanning **Experience Cloud, Apex, Lightning Web Components, Flows, Service Cloud, Agentforce (AI), and a Stripe payment integration.**

> ⚠️ **Demo / portfolio project.** Built on a Salesforce Developer Edition org in Stripe **test mode**. No real personal or payment data — visitors are asked to use test data and the Stripe test card.

---

## What it does

**For the public (guest users, no login):**
- Browse dance classes with rich detail (instructor, schedule, fee, capacity) in an interactive catalog
- **Enroll and pay online** via Stripe Checkout — enrollment is confirmed automatically when payment succeeds
- See **live class availability** — full classes are blocked from enrollment
- Register (RSVP) for events, including **paid events** through the same payment pipeline
- Get help from an **AI assistant** (Agentforce) that recommends classes, answers questions, captures enquiries, and logs support cases
- Submit enquiries (Web-to-Lead) and support requests (Web-to-Case) with automated acknowledgment

**For administrators:**
- A custom **Lightning App** with a command-center home page showing two live dashboards (business performance + service SLA)
- Full visibility into enrollments, payments, events, RSVPs, leads, and cases
- **SLA management** on support cases with priority assignment and milestones
- Reporting across enrollments, revenue, status funnels, events, and leads

---

## Architecture highlights

### Stripe payment integration (end-to-end)
- Secure callouts using **Named / External Credentials** — no secret keys in code
- Two-step enrollment flow respecting Salesforce's **callout-after-DML** rule
- **Stripe Checkout** session creation with the Salesforce record id passed in payment metadata
- A public **Apex REST webhook** that confirms enrollments/RSVPs and writes payment records when Stripe reports success — handling both class enrollments and event registrations
- Robust, version-proof webhook parsing using untyped JSON

### Agentforce AI agent (deployed live)
- A customer-facing conversational agent built with **Agent Script** and multiple subagents
- Grounded in **live org data** (real classes and events) to prevent hallucination
- Creates leads and support cases; hands off responsibly for transactions
- Deployed to the public site via Omni-Channel + Embedded Messaging

### Live class capacity
- Real-time availability computed from confirmed enrollments (no stored counter to drift)
- **Defense in depth:** full classes are blocked both in the UI and enforced server-side in Apex

### Service Cloud + SLA
- Web-to-Case intake with before-save priority assignment
- Entitlements and milestones for SLA tracking, surfaced on an SLA dashboard

---

## Tech stack

| Layer | Technology |
|---|---|
| Public site | Experience Cloud (LWR), Lightning Web Components, HTML/CSS |
| Backend logic | Apex (`@AuraEnabled` controllers, `@RestResource` webhook, `@InvocableMethod` agent actions) |
| Automation | Record-triggered Flows, before-save Flows, Auto-Response Rules |
| AI | Agentforce (Agent Script, subagents, Apex/Flow actions) |
| Payments | Stripe Checkout + webhooks, Named/External Credentials |
| Service | Service Cloud, Entitlements, Milestones, Web-to-Case |
| Data | 5 custom objects (Dance Class, Enrollment, Payment, Event, RSVP) |
| Admin | Custom Lightning App, Reports, Dashboards |

---

## Custom data model

- **Dance Class** — the class catalog (style, instructor, schedule, fee, capacity)
- **Enrollment** — a student's enrollment in a class, with payment status
- **Payment** — payment audit records (master-detail to Enrollment)
- **Event** — academy events and performances
- **RSVP** — event registrations (master-detail to Event)

Plus standard objects: Contact, Lead, Case (with Entitlements/Milestones).

---

## Documentation

Detailed write-ups of the harder integrations live in [`/docs`](./docs):

- **Integrating Stripe Payments with Salesforce** — full account of the payment architecture, the webhook, and every gotcha solved along the way
- **Stripe + Salesforce Interview Prep** — deep-dive reference on the credential setup, the callout/webhook design, and the debugging journey
- **Building & Deploying an Agentforce Agent** — the AI agent build and live deployment

---

## Roadmap (v2)

Planned enhancements, deliberately scoped out of the MVP:

- **Admin Assistant agent** — an internal-facing Agentforce agent for operational insight ("what needs attention today?") and, in later iterations, safe automation
- **Spot reservation during checkout** — hold a class spot for "awaiting payment" enrollments with timed release of abandoned reservations
- **Unified payment audit for events** — extend payment records to event RSVPs
- **Pre-filled enrollment** — carry the selected class through from the catalog into the enrollment form

---

## Notes

- Admin awareness is handled through **real-time dashboards** (and a planned Admin Assistant agent) rather than per-record email notifications, to avoid inbox noise.
- This repository contains the code metadata (Apex, LWC, Flows, objects, permission sets). Org configuration that isn't code — Experience Cloud site content, Agentforce agent config, Stripe credentials, Omni-Channel/Messaging setup — lives in the org and is described in the documentation.
