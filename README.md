# Shree Aadrika Quote Studio

Flutter quotation, pricing, inventory and CRM prototype for SHREE AADRIKA INNOVATIONS LLP.

## Included
- Dashboard, quotation, customers, available stock, follow-up and settings.
- GSM/material/handle/quantity/supplier-rate/landed-rate stock selection.
- Quotation status: Draft, Sent, Negotiation, Converted, Not Converted, Lost, Expired.
- Editing creates a new quotation version and timestamp.
- Discount, GST, advance, negotiation, manufacturing cost, landing cost, ₹3.16 business overhead, floor cost and margin.
- A4 PDF quotation with bank details, payment terms and terms & conditions.
- Call, WhatsApp and email launch actions.

## Bootstrap
From the project root:

```powershell
flutter pub get
flutter create .
flutter analyze
flutter run -d windows
```

For Android Studio/Android:

```powershell
flutter run
```

Open the folder containing `pubspec.yaml` in Android Studio, not only the `lib` folder.

## Logo
The exact uploaded logo image is not stored by the current GitHub connector because it only writes text files. Put the original image at `assets/aadrika_logo.png` and wire that binary asset into launcher configuration.

## Agent plan
See `AGENTS.md`. Specialist passes cover workflow, cost engine, inventory, quotation/PDF, CRM/communication and QA. The QA pass must run `dart analyze` and platform builds rather than patching syntax errors blindly.
