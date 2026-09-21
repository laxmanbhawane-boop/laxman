# Aadrika Quote Studio build agents

This project is designed to be maintained by a sequence of specialist passes rather than repeatedly patching one large `main.dart` file.

## Agent 1 — Product / workflow
Owns quotation lifecycle, customer master, stock selection, negotiation, follow-up, status and versioning.

Acceptance:
- Quote status: Draft, Sent, Negotiation, Converted, Not Converted, Lost, Expired.
- Editing a quote creates a new version and never mutates the historical version.
- Timestamp is captured for every generated version.

## Agent 2 — Cost engine
Owns supplier rate, landing/transport, manufacturing, business overhead, floor cost, margin, discount, GST and negotiated selling rate.

Acceptance:
- GSM and handle come from the selected stock item.
- Business overhead default is ₹3.16/bag and remains editable in master settings.
- GST and advance are variable, never hard-coded as permanent business rules.
- Floor-cost warning/override is explicit.
- No silent 000/zero values when a valid stock row is selected.

## Agent 3 — Inventory
Owns available-stock import/manual entry and filters for size, material, GSM, handle and quantity.

Acceptance:
- A stock row can be selected directly from quotation entry.
- Quantity cannot silently exceed available stock without an explicit override.
- Supplier rate and landed rate remain separate.

## Agent 4 — Quotation/PDF
Owns A4 quotation layout, company/customer blocks, item table, totals, payment terms, bank details and terms & conditions.

Acceptance:
- Bank details are included.
- Advance %, advance amount and balance before dispatch are included.
- Cheque/DD acceptance and name/account validation rule is included.
- PDF preserves quote number, version and generation timestamp.

## Agent 5 — CRM / communication
Owns call, WhatsApp, email, calendar/follow-up and contact data.

Acceptance:
- Customer phone/email are reused automatically in communication actions.
- Follow-up records link back to quotation and customer.
- WhatsApp/email failures show a clear user-facing error instead of silently failing.

## Agent 6 — QA
Run `dart analyze`, `flutter test`, then platform builds. Never respond to a syntax error by adding random closing brackets. If a file becomes difficult to reason about, split it into services/screens/models.

## Current implementation
The first pass is intentionally dependency-light and keeps the core workflow in one clean Dart entry point so it can be bootstrapped quickly. The next refactor should split `main.dart` into models, services, screens and PDF/communication services after the workflow is accepted.
