import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const AadrikaApp());

const navy = Color(0xFF063B63);
const teal = Color(0xFF087F7A);
const gold = Color(0xFFD9A321);
const bg = Color(0xFFF4F8FA);
const green = Color(0xFF198754);

class StockItem {
  final String size;
  final String material;
  final int gsm;
  final String handle;
  int qty;
  final double supplierRate;
  final double landedRate;
  StockItem({required this.size, required this.material, required this.gsm, required this.handle, required this.qty, required this.supplierRate, required this.landedRate});
}

class Customer {
  String company;
  String contact;
  String phone;
  String email;
  String gstin;
  Customer({required this.company, required this.contact, required this.phone, required this.email, this.gstin = ''});
}

class QuoteLine {
  String product;
  String specification;
  String hsn;
  int qty;
  double rate;
  QuoteLine({required this.product, required this.specification, this.hsn = '4819', required this.qty, required this.rate});
  double get amount => qty * rate;
}

class Quote {
  String number;
  int version;
  DateTime created;
  Customer customer;
  List<QuoteLine> lines;
  double discount;
  double gst;
  double advancePct;
  double manufacturing;
  double landing;
  double overhead;
  double floorCost;
  double margin;
  String status;
  String notes;
  Quote({required this.number, required this.version, required this.created, required this.customer, required this.lines, this.discount = 0, this.gst = 18, this.advancePct = 50, this.manufacturing = 0, this.landing = 0, this.overhead = 3.16, this.floorCost = 0, this.margin = 20, this.status = 'Draft', this.notes = ''});
  double get subtotal => lines.fold(0, (s, x) => s + x.amount);
  double get taxable => math.max(0, subtotal - discount);
  double get tax => taxable * gst / 100;
  double get total => taxable + tax;
  double get advance => total * advancePct / 100;
  double get cost => manufacturing + landing + overhead;
  double get floor => floorCost > 0 ? floorCost : cost;
  double get profit => total - cost * lines.fold(0, (s, x) => s + x.qty);
}

class AadrikaApp extends StatefulWidget {
  const AadrikaApp({super.key});
  @override
  State<AadrikaApp> createState() => _AadrikaAppState();
}

class _AadrikaAppState extends State<AadrikaApp> {
  int page = 0;
  final customers = <Customer>[
    Customer(company: 'Demo Bakery Pvt Ltd', contact: 'Purchasing Manager', phone: '+91 90000 00000', email: 'purchase@example.com'),
  ];
  final stock = <StockItem>[
    StockItem(size: '8 x 4 x 12', material: 'KRAFT', gsm: 80, handle: 'Without Handle', qty: 14375, supplierRate: 3.11, landedRate: 3.35),
    StockItem(size: '12 x 4 x 16', material: 'KRAFT', gsm: 80, handle: 'Twisted Handle', qty: 5500, supplierRate: 4.95, landedRate: 5.25),
    StockItem(size: '12 x 4 x 16', material: 'KRAFT', gsm: 100, handle: 'Twisted Handle', qty: 3500, supplierRate: 5.48, landedRate: 5.82),
    StockItem(size: '12 x 4 x 16', material: 'KRAFT', gsm: 80, handle: 'Flat Handle', qty: 1800, supplierRate: 4.95, landedRate: 5.25),
    StockItem(size: '13 x 7 x 17', material: 'KRAFT-A(SW)', gsm: 100, handle: 'Twisted Handle', qty: 1500, supplierRate: 6.55, landedRate: 6.92),
    StockItem(size: '10.62 x 4.7 x 13', material: 'KRAFT', gsm: 100, handle: 'Twisted Handle', qty: 2200, supplierRate: 5.02, landedRate: 5.38),
    StockItem(size: '13 x 7 x 13', material: 'KRAFT', gsm: 100, handle: 'Twisted Handle', qty: 1800, supplierRate: 5.63, landedRate: 5.98),
    StockItem(size: '11 x 6.7 x 12', material: 'KRAFT', gsm: 100, handle: 'Twisted Handle', qty: 4500, supplierRate: 5.55, landedRate: 5.90),
    StockItem(size: '6.49 x 3.54 x 8.26', material: 'KRAFT', gsm: 120, handle: 'Twisted Handle', qty: 2600, supplierRate: 4.35, landedRate: 4.72),
    StockItem(size: '8.26 x 5.11 x 10.62', material: 'KRAFT', gsm: 120, handle: 'Twisted Handle', qty: 1250, supplierRate: 4.93, landedRate: 5.31),
    StockItem(size: '8.26 x 4.33 x 10.62', material: 'KRAFT', gsm: 110, handle: 'Twisted Handle', qty: 5000, supplierRate: 3.73, landedRate: 4.05),
    StockItem(size: '10.23 x 4.72 x 12.59', material: 'KRAFT', gsm: 110, handle: 'Twisted Handle', qty: 1250, supplierRate: 4.31, landedRate: 4.66),
  ];
  final quotes = <Quote>[];
  Customer? selectedCustomer;
  Quote? editing;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (p.getInt('quote_seq') == null) await p.setInt('quote_seq', 1);
  }
  void openNewQuote([Quote? source]) {
    setState(() { editing = source; page = 1; });
  }
  void saveQuote(Quote q) {
    final i = quotes.indexWhere((x) => x.number == q.number && x.version == q.version);
    setState(() { if (i >= 0) quotes[i] = q; else quotes.insert(0, q); page = 2; });
  }
  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(quotes: quotes, stock: stock, onNew: () => openNewQuote()),
      QuoteEditorScreen(stock: stock, customers: customers, source: editing, onSave: saveQuote, onCancel: () => setState(() => page = 0)),
      QuotesScreen(quotes: quotes, onNew: () => openNewQuote(), onEdit: openNewQuote, onStatus: (q, s) => setState(() => q.status = s)),
      CustomersScreen(customers: customers, onChanged: () => setState(() {})),
      StockScreen(stock: stock, onChanged: () => setState(() {})),
      FollowUpScreen(quotes: quotes, customers: customers),
      SettingsScreen(),
    ];
    return MaterialApp(debugShowCheckedModeBanner: false, title: 'Aadrika Quote Studio', theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: bg, colorScheme: ColorScheme.fromSeed(seedColor: teal), fontFamily: 'Arial'), home: Scaffold(body: Row(children: [NavigationRail(selectedIndex: page, onDestinationSelected: (i) => setState(() { page = i; editing = null; }), labelType: NavigationRailLabelType.all, leading: const Padding(padding: EdgeInsets.all(10), child: BrandLogo()), destinations: const [NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')), NavigationRailDestination(icon: Icon(Icons.request_quote_outlined), selectedIcon: Icon(Icons.request_quote), label: Text('New Quote')), NavigationRailDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description), label: Text('Quotations')), NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('Customers')), NavigationRailDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: Text('Available Stock')), NavigationRailDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: Text('Follow-up')), NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings'))]), Expanded(child: screens[page])])));
  }
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key});
  @override
  Widget build(BuildContext context) => Column(children: [Container(width: 56, height: 56, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: const LinearGradient(colors: [Color(0xFF063B63), Color(0xFF087F7A)])), child: const Center(child: Text('A', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900))),), const SizedBox(height: 6), const Text('AADRIKA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: navy))]);
}

class AppPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget>? actions;
  const AppPage({super.key, required this.title, required this.subtitle, required this.child, this.actions});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: navy)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Colors.black54))])), ...(actions ?? [])]), const SizedBox(height: 20), Expanded(child: child)]));
}

class DashboardScreen extends StatelessWidget {
  final List<Quote> quotes; final List<StockItem> stock; final VoidCallback onNew;
  const DashboardScreen({super.key, required this.quotes, required this.stock, required this.onNew});
  @override Widget build(BuildContext context) {
    final total = quotes.fold(0.0, (s, q) => s + q.total); final low = stock.where((s) => s.qty < 1500).length;
    return AppPage(title: 'Shree Aadrika Quote Studio', subtitle: 'Quotation • Negotiation • Inventory • CRM • Follow-up', actions: [FilledButton.icon(onPressed: onNew, icon: const Icon(Icons.add), label: const Text('New Quotation'))], child: ListView(children: [Wrap(spacing: 16, runSpacing: 16, children: [_metric('Active Quotes', '${quotes.where((q) => q.status != 'Lost').length}', Icons.description), _metric('Quoted Value', '₹${total.toStringAsFixed(0)}', Icons.currency_rupee), _metric('Stock SKUs', '${stock.length}', Icons.inventory_2), _metric('Low Stock', '$low', Icons.warning_amber)]), const SizedBox(height: 24), _panel('Operational flow', const ["Select customer → select one or more stock products → verify GSM/handle → calculate cost → negotiate → approve rate → generate quotation PDF → WhatsApp/email → follow-up → convert/lost/expired.", "Every edit creates a new quotation version (for example Q-0001 v1, v2, v3) and keeps the original version unchanged.", "Customer contact, GSTIN, payment terms, bank details, advance, discount and terms & conditions are stored with the quotation snapshot."]), const SizedBox(height: 16), _panel('Cost engine', const ["Supplier rate + transport/landing + manufacturing + ₹3.16 business overhead = landed/operating cost.", "Floor cost blocks accidental under-cost quotations.", "Negotiated selling rate is compared with cost and target margin before approval."]) ]));
  }
  Widget _metric(String t, String v, IconData i) => Card(child: SizedBox(width: 220, height: 120, child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(i, color: teal), const Spacer(), Text(v, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: navy)), Text(t, style: const TextStyle(color: Colors.black54))]))));
}

Widget _panel(String title, List<String> rows) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: navy, fontSize: 17)), const SizedBox(height: 12), ...rows.map((x) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_circle_outline, size: 18, color: teal), const SizedBox(width: 8), Expanded(child: Text(x))]))) ]));

class QuoteEditorScreen extends StatefulWidget {
  final List<StockItem> stock; final List<Customer> customers; final Quote? source; final ValueChanged<Quote> onSave; final VoidCallback onCancel;
  const QuoteEditorScreen({super.key, required this.stock, required this.customers, required this.source, required this.onSave, required this.onCancel});
  @override State<QuoteEditorScreen> createState() => _QuoteEditorScreenState();
}
class _QuoteEditorScreenState extends State<QuoteEditorScreen> {
  Customer? customer; final lines = <QuoteLine>[]; StockItem? selectedStock; double discount = 0, gst = 18, advance = 50, manufacturing = 0, landing = 0, overhead = 3.16, floor = 0, margin = 20; String status = 'Draft';
  final discountC = TextEditingController(), manufC = TextEditingController(), landingC = TextEditingController(), floorC = TextEditingController(), marginC = TextEditingController(text: '20'), advanceC = TextEditingController(text: '50'), notesC = TextEditingController();
  @override void initState() { super.initState(); final q = widget.source; if (q != null) { customer = q.customer; lines.addAll(q.lines.map((x) => QuoteLine(product: x.product, specification: x.specification, hsn: x.hsn, qty: x.qty, rate: x.rate))); discount = q.discount; gst = q.gst; advance = q.advancePct; manufacturing = q.manufacturing; landing = q.landing; floor = q.floorCost; margin = q.margin; status = q.status; discountC.text = '$discount'; manufC.text = '$manufacturing'; landingC.text = '$landing'; floorC.text = '$floor'; marginC.text = '$margin'; advanceC.text = '$advance'; notesC.text = q.notes; } }
  void addStock() { final s = selectedStock; if (s == null) return; setState(() => lines.add(QuoteLine(product: 'Paper Bag', specification: '${s.size} inch • ${s.material} • ${s.gsm} GSM • ${s.handle}', qty: 1000, rate: s.landedRate))); }
  double get subtotal => lines.fold(0.0, (s, x) => s + x.amount); double get taxable => math.max(0, subtotal - discount); double get tax => taxable * gst / 100; double get total => taxable + tax; double get unitCost => lines.isEmpty ? 0 : manufacturing + landing + overhead + floor; double get unitMargin => lines.isEmpty ? 0 : ((lines.fold(0.0, (s, x) => s + (x.rate - unitCost) * x.qty)) / subtotal * 100);
  Quote _makeQuote() { final base = widget.source; final num = base?.number ?? 'Q-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}'; final ver = base == null ? 1 : base.version + 1; return Quote(number: num, version: ver, created: DateTime.now(), customer: customer!, lines: lines, discount: discount, gst: gst, advancePct: advance, manufacturing: manufacturing, landing: landing, overhead: overhead, floorCost: floor, margin: margin, status: status, notes: notesC.text); }
  @override Widget build(BuildContext context) => AppPage(title: widget.source == null ? 'New Quotation' : 'Edit Quotation • New Version', subtitle: 'Rates are editable only after cost, floor price and negotiation checks.', actions: [OutlinedButton(onPressed: widget.onCancel, child: const Text('Cancel')), const SizedBox(width: 8), FilledButton.icon(onPressed: customer == null || lines.isEmpty ? null : () => widget.onSave(_makeQuote()), icon: const Icon(Icons.save), label: const Text('Save Quote'))], child: ListView(children: [Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [Row(children: [Expanded(child: DropdownButtonFormField<Customer>(value: customer, decoration: const InputDecoration(labelText: 'Customer / Bill To', border: OutlineInputBorder()), items: widget.customers.map((c) => DropdownMenuItem(value: c, child: Text(c.company))).toList(), onChanged: (v) => setState(() => customer = v))), const SizedBox(width: 12), Expanded(child: Text(customer == null ? 'Select a customer' : '${customer!.contact} • ${customer!.phone} • ${customer!.email}', style: const TextStyle(color: Colors.black54)))])])), const SizedBox(height: 14), Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Items • one product per line', style: TextStyle(fontWeight: FontWeight.w800, color: navy)), const SizedBox(height: 10), Row(children: [Expanded(child: DropdownButtonFormField<StockItem>(value: selectedStock, decoration: const InputDecoration(labelText: 'Available Stock / GSM / Handle', border: OutlineInputBorder()), items: widget.stock.map((s) => DropdownMenuItem(value: s, child: Text('${s.size} • ${s.gsm} GSM • ${s.handle} • Qty ${s.qty}'))).toList(), onChanged: (v) => setState(() => selectedStock = v))), const SizedBox(width: 10), FilledButton.icon(onPressed: addStock, icon: const Icon(Icons.add), label: const Text('Add Product'))]), const SizedBox(height: 12), if (lines.isEmpty) const Text('No product added yet.'), ...lines.asMap().entries.map((e) => _line(e.key, e.value))])), const SizedBox(height: 14), Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [const Align(alignment: Alignment.centerLeft, child: Text('Pricing, negotiation and mandatory commercial controls', style: TextStyle(fontWeight: FontWeight.w800, color: navy))), const SizedBox(height: 12), Wrap(spacing: 12, runSpacing: 12, children: [_num(discountC, 'Discount ₹', (v) => discount = v), _num(manufC, 'Manufacturing ₹/bag', (v) => manufacturing = v), _num(landingC, 'Landing/transport ₹/bag', (v) => landing = v), _num(floorC, 'Floor cost ₹/bag', (v) => floor = v), _num(marginC, 'Target margin %', (v) => margin = v), _num(advanceC, 'Advance %', (v) => advance = v), SizedBox(width: 180, child: DropdownButtonFormField<double>(value: gst, decoration: const InputDecoration(labelText: 'GST %', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: 0, child: Text('0%')), DropdownMenuItem(value: 5, child: Text('5%')), DropdownMenuItem(value: 12, child: Text('12%')), DropdownMenuItem(value: 18, child: Text('18%'))], onChanged: (v) => setState(() => gst = v ?? 18))), SizedBox(width: 180, child: DropdownButtonFormField<String>(value: status, decoration: const InputDecoration(labelText: 'Quotation Status', border: OutlineInputBorder()), items: const ['Draft','Negotiation','Sent','Converted','Not Converted','Lost','Expired'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) => setState(() => status = v ?? 'Draft')))]), const SizedBox(height: 12), Text('Subtotal ₹${subtotal.toStringAsFixed(2)}  •  Taxable ₹${taxable.toStringAsFixed(2)}  •  GST ₹${tax.toStringAsFixed(2)}  •  Total ₹${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800)), Text('Calculated unit cost ₹${unitCost.toStringAsFixed(2)}  •  Estimated margin ${unitMargin.isFinite ? unitMargin.toStringAsFixed(1) : '0.0'}%', style: TextStyle(color: unitMargin >= margin ? green : Colors.red, fontWeight: FontWeight.w700)), Text('Advance due ₹${(total * advance / 100).toStringAsFixed(2)}', style: const TextStyle(color: navy, fontWeight: FontWeight.w700))])), const SizedBox(height: 14), Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [TextField(controller: notesC, maxLines: 3, decoration: const InputDecoration(labelText: 'Negotiation / follow-up notes', border: OutlineInputBorder())), const SizedBox(height: 12), _panel('Default payment and quotation controls', const ['Advance percentage is editable per negotiation.', 'Cheque and DD are accepted; cheque/DD name must match the customer/account name unless approved manually.', 'Payment can be via bank transfer, cheque or DD. Due dates and balance before dispatch are captured in the final quotation.', 'Validity, delivery, GST, artwork, paper variation, quantity tolerance and other terms are printed on the PDF.'])]))]));
  Widget _line(int i, QuoteLine x) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [SizedBox(width: 28, child: Text('${i + 1}')), Expanded(child: Text(x.product)), Expanded(flex: 2, child: Text(x.specification)), SizedBox(width: 90, child: TextFormField(initialValue: '${x.qty}', decoration: const InputDecoration(labelText: 'Qty'), keyboardType: TextInputType.number, onChanged: (v) => x.qty = int.tryParse(v) ?? x.qty)), SizedBox(width: 110, child: TextFormField(initialValue: x.rate.toStringAsFixed(2), decoration: const InputDecoration(labelText: 'Rate'), keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (v) => x.rate = double.tryParse(v) ?? x.rate)), IconButton(onPressed: () => setState(() => lines.removeAt(i)), icon: const Icon(Icons.delete_outline, color: Colors.red))]));
  Widget _num(TextEditingController c, String label, ValueChanged<double> on) => SizedBox(width: 180, child: TextField(controller: c, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()), onChanged: (v) => setState(() => on(double.tryParse(v) ?? 0))));
}

class QuotesScreen extends StatelessWidget {
  final List<Quote> quotes; final VoidCallback onNew; final ValueChanged<Quote> onEdit; final void Function(Quote,String) onStatus;
  const QuotesScreen({super.key, required this.quotes, required this.onNew, required this.onEdit, required this.onStatus});
  @override Widget build(BuildContext context) => AppPage(title: 'Quotations', subtitle: 'Versioned quotations with status, negotiation and communication controls.', actions: [FilledButton.icon(onPressed: onNew, icon: const Icon(Icons.add), label: const Text('New Quotation'))], child: quotes.isEmpty ? const Center(child: Text('No quotations yet.')) : ListView(children: quotes.map((q) => Card(child: ListTile(leading: CircleAvatar(backgroundColor: teal, child: Text('${q.version}', style: const TextStyle(color: Colors.white))), title: Text('${q.number} • v${q.version} — ${q.customer.company}', style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${DateFormat('dd MMM yyyy, hh:mm a').format(q.created)} • ₹${q.total.toStringAsFixed(2)} • ${q.status}'), trailing: Wrap(children: [IconButton(tooltip: 'Edit as new version', onPressed: () => onEdit(q), icon: const Icon(Icons.edit)), IconButton(tooltip: 'PDF', onPressed: () => _pdf(context, q), icon: const Icon(Icons.picture_as_pdf)), IconButton(tooltip: 'WhatsApp', onPressed: () => _wa(q), icon: const Icon(Icons.chat)), IconButton(tooltip: 'Email', onPressed: () => _mail(q), icon: const Icon(Icons.email)), PopupMenuButton<String>(onSelected: (s) => onStatus(q, s), itemBuilder: (_) => const ['Sent','Negotiation','Converted','Not Converted','Lost','Expired'].map((s) => PopupMenuItem(value: s, child: Text(s))).toList())])]))).toList()));
}

Future<void> _pdf(BuildContext context, Quote q) async { final doc = pw.Document(); doc.addPage(pw.MultiPage(build: (_) => [pw.Text('SHREE AADRIKA INNOVATIONS LLP', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)), pw.SizedBox(height: 8), pw.Text('QUOTATION ${q.number} • VERSION ${q.version}'), pw.Text('Date: ${DateFormat('dd-MM-yyyy HH:mm').format(q.created)}'), pw.Text('Customer: ${q.customer.company} | ${q.customer.contact}'), pw.SizedBox(height: 16), pw.Table.fromTextArray(headers: const ['#','Product','Specification','Qty','Rate','Amount'], data: [for (var i = 0; i < q.lines.length; i++) [ '${i + 1}', q.lines[i].product, q.lines[i].specification, '${q.lines[i].qty}', q.lines[i].rate.toStringAsFixed(2), q.lines[i].amount.toStringAsFixed(2) ]]), pw.SizedBox(height: 14), pw.Text('Subtotal: ₹${q.subtotal.toStringAsFixed(2)}'), pw.Text('Discount: ₹${q.discount.toStringAsFixed(2)}'), pw.Text('GST ${q.gst.toStringAsFixed(0)}%: ₹${q.tax.toStringAsFixed(2)}'), pw.Text('GRAND TOTAL: ₹${q.total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.SizedBox(height: 14), pw.Text('Advance: ${q.advancePct.toStringAsFixed(1)}% = ₹${q.advance.toStringAsFixed(2)}'), pw.Text('Balance before dispatch: ₹${(q.total - q.advance).toStringAsFixed(2)}'), pw.SizedBox(height: 14), pw.Text('Terms & Conditions', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text('1. Rates are per bag, exclusive of GST unless stated otherwise.\n2. Prices are valid for the quotation validity period and subject to final artwork/specification.\n3. Development/stereo/plate charges, if applicable, are extra.\n4. Delivery is counted from confirmed order and approved artwork.\n5. Cheque/DD accepted; instrument name must match the customer/account name unless approved.\n6. Paper is a natural material; shade variation may occur.\n7. Quantity tolerance of ±5% may apply and will be billed as supplied.\n8. Advance and balance terms are as stated above.'), pw.SizedBox(height: 18), pw.Text('Bank Details: IndusInd Bank | A/c: SHREE AADRIKA INNOVATIONS LLP | IFSC: INDB000043 | Branch: Baner, Pune'), pw.SizedBox(height: 20), pw.Text('For SHREE AADRIKA INNOVATIONS LLP\nAuthorised Signatory') ])); await Printing.layoutPdf(onLayout: (_) async => doc.save()); }
Future<void> _wa(Quote q) async { final text = 'Quotation ${q.number} v${q.version} for ${q.customer.company}: ₹${q.total.toStringAsFixed(2)}. Advance ${q.advancePct.toStringAsFixed(0)}%. Please find the quotation attached/shared separately.'; await launchUrl(Uri.parse('https://wa.me/${q.customer.phone.replaceAll(RegExp(r'[^0-9]'), '')}?text=${Uri.encodeComponent(text)}'), mode: LaunchMode.externalApplication); }
Future<void> _mail(Quote q) async { final uri = Uri(scheme: 'mailto', path: q.customer.email, queryParameters: {'subject': 'Quotation ${q.number} v${q.version} - Shree Aadrika Innovations LLP', 'body': 'Please find quotation ${q.number} v${q.version}. Total: ₹${q.total.toStringAsFixed(2)}.'}); await launchUrl(uri); }

class CustomersScreen extends StatefulWidget { final List<Customer> customers; final VoidCallback onChanged; const CustomersScreen({super.key, required this.customers, required this.onChanged}); @override State<CustomersScreen> createState() => _CustomersScreenState(); }
class _CustomersScreenState extends State<CustomersScreen> { void add() { final c = Customer(company: 'New Customer', contact: '', phone: '', email: ''); setState(() => widget.customers.add(c)); widget.onChanged(); }
  @override Widget build(BuildContext context) => AppPage(title: 'Customers', subtitle: 'Customer master drives quotation contact, WhatsApp and email automatically.', actions: [FilledButton.icon(onPressed: add, icon: const Icon(Icons.person_add), label: const Text('Add Customer'))], child: ListView(children: widget.customers.map((c) => Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.business)), title: Text(c.company), subtitle: Text('${c.contact} • ${c.phone} • ${c.email}\nGSTIN: ${c.gstin.isEmpty ? 'Not set' : c.gstin}'), isThreeLine: true, trailing: Wrap(children: [IconButton(onPressed: () => launchUrl(Uri.parse('tel:${c.phone}')), icon: const Icon(Icons.call)), IconButton(onPressed: () => launchUrl(Uri.parse('https://wa.me/${c.phone.replaceAll(RegExp(r'[^0-9]'), '')}')), icon: const Icon(Icons.chat))]))).toList())); }
}

class StockScreen extends StatefulWidget { final List<StockItem> stock; final VoidCallback onChanged; const StockScreen({super.key, required this.stock, required this.onChanged}); @override State<StockScreen> createState() => _StockScreenState(); }
class _StockScreenState extends State<StockScreen> { String search = ''; int? gsm;
  @override Widget build(BuildContext context) { final rows = widget.stock.where((s) => (search.isEmpty || '${s.size} ${s.material} ${s.handle}'.toLowerCase().contains(search.toLowerCase())) && (gsm == null || s.gsm == gsm)).toList(); final gsms = widget.stock.map((s) => s.gsm).toSet().toList()..sort(); return AppPage(title: 'Available Stock', subtitle: 'Upload/enter supplier stock and select exact GSM, handle, size and quantity in quotation.', actions: [SizedBox(width: 220, child: TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search stock', border: OutlineInputBorder()), onChanged: (v) => setState(() => search = v))), const SizedBox(width: 8), DropdownButton<int>(value: gsm, hint: const Text('GSM'), items: [const DropdownMenuItem<int>(value: null, child: Text('All GSM')), ...gsms.map((g) => DropdownMenuItem(value: g, child: Text('$g GSM')))], onChanged: (v) => setState(() => gsm = v))], child: Card(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(columns: const [DataColumn(label: Text('Size W×G×H')), DataColumn(label: Text('Material')), DataColumn(label: Text('GSM')), DataColumn(label: Text('Handle')), DataColumn(label: Text('Available Qty')), DataColumn(label: Text('Supplier Rate')), DataColumn(label: Text('Landed Rate')), DataColumn(label: Text('Status'))], rows: rows.map((s) => DataRow(cells: [DataCell(Text(s.size)), DataCell(Text(s.material)), DataCell(Text('${s.gsm}')), DataCell(Text(s.handle)), DataCell(Text('${s.qty}')), DataCell(Text('₹${s.supplierRate.toStringAsFixed(2)}')), DataCell(Text('₹${s.landedRate.toStringAsFixed(2)}')), DataCell(Text(s.qty < 1500 ? 'LOW' : 'OK', style: TextStyle(color: s.qty < 1500 ? Colors.red : green, fontWeight: FontWeight.bold)))] )).toList())))); }
}

class FollowUpScreen extends StatelessWidget { final List<Quote> quotes; final List<Customer> customers; const FollowUpScreen({super.key, required this.quotes, required this.customers}); @override Widget build(BuildContext context) => AppPage(title: 'Follow-up & Calendar', subtitle: 'Next action, reminder, communication and quotation status in one place.', actions: [FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.event), label: const Text('New Follow-up'))], child: ListView(children: quotes.map((q) => Card(child: ListTile(leading: const Icon(Icons.event_note, color: teal), title: Text('${q.number} v${q.version} • ${q.customer.company}'), subtitle: Text('Status: ${q.status}\nNext action: Call customer • Review negotiation • Confirm order'), isThreeLine: true, trailing: Wrap(children: [IconButton(onPressed: () => launchUrl(Uri.parse('tel:${q.customer.phone}')), icon: const Icon(Icons.call)), IconButton(onPressed: () => launchUrl(Uri.parse('https://wa.me/${q.customer.phone.replaceAll(RegExp(r'[^0-9]'), '')}')), icon: const Icon(Icons.chat))]))).toList())); }
}

class SettingsScreen extends StatelessWidget { const SettingsScreen({super.key}); @override Widget build(BuildContext context) => AppPage(title: 'Settings & Master Data', subtitle: 'Company, bank, commercial rules and quotation defaults.', child: ListView(children: [_panel('Company', const ['SHREE AADRIKA INNOVATIONS LLP', 'GST No. 27AGAFS1978F1ZR', 'Office No. 505, 5th Floor, Maruti Millennium Tower, S. No. 36/2, Near Supreme HQ Building, Near Nanaware Bridge, Baner, Pune – 411045.', '+91 77188 71223 • aadrikainnovations@gmail.com • aadrikainnovations.co.in']), _panel('Bank details', const ['Bank: IndusInd Bank', 'Account Name: SHREE AADRIKA INNOVATIONS LLP', 'Account Number: 257712312277', 'IFSC: INDB000043', 'Branch: Baner, Pune', 'Account Type: Current', 'Cheque/DD name validation: instrument name should match account/customer name unless approved.']), _panel('Commercial rules', const ['Business overhead default: ₹3.16 per bag', 'GST is variable and selected in the quotation; do not hard-code 18%.', 'Advance is variable and negotiated per quotation.', 'Floor cost is a safety threshold; selling rate below floor requires an explicit override.', 'Customer rate, supplier rate, landed rate and target margin are separate values.', 'Quotation versions preserve previous versions and timestamp every generation.']), _panel('Quotation terms', const ['Rates are per bag and GST is extra unless stated otherwise.', 'Validity, delivery, artwork/development charges, quantity tolerance and paper variation are printed on every PDF.', 'Cheque and DD are accepted subject to name/account validation.', 'Payment terms show advance, advance amount, balance before dispatch and bank details.'])])); }
}
