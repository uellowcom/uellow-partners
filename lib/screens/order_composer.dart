// New customer order — agent fills customer + items, submits for review.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../api.dart';
import '../main.dart';

class OrderComposer extends StatefulWidget {
  const OrderComposer({super.key});
  @override
  State<OrderComposer> createState() => _OrderComposerState();
}

class _OrderComposerState extends State<OrderComposer> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _area = TextEditingController();
  final _address = TextEditingController();
  final _note = TextEditingController();
  final List<Map<String, dynamic>> _lines = [];
  bool _busy = false;

  Future<void> _pickProduct() async {
    final ar = PartnersApi.instance.lang == 'ar';
    final qCtrl = TextEditingController();
    List<Map<String, dynamic>> results = [];
    await showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius:
          BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        Future<void> search() async {
          try {
            final v = await PartnersApi.instance
                .products(q: qCtrl.text.trim());
            setSheet(() => results = v);
          } catch (_) {}
        }
        if (results.isEmpty && qCtrl.text.isEmpty) search();
        return SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.75,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: TextField(
                controller: qCtrl,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => search(),
                decoration: InputDecoration(
                  hintText: ar ? 'ابحث عن منتج…' : 'Search a product…',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            Expanded(child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (_, i) {
                final m = results[i];
                final nm = (((m['name'] as Map?)?[ar ? 'ar' : 'en'])
                    ?? (m['name'] as Map?)?['en'] ?? '').toString();
                final img = (m['image'] as String?) ?? '';
                final price =
                    ((m['price'] as Map?)?['amount'] as num?) ?? 0;
                final comm = ((m['commission_amount']
                    as Map?)?['amount'] as num?) ?? 0;
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                        imageUrl: img.startsWith('http')
                            ? img : '${PartnersApi.baseUrl}$img',
                        width: 44, height: 44, fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const ColoredBox(
                            color: Color(0xFFEFEFEF))),
                  ),
                  title: Text(nm, maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5)),
                  subtitle: Text(
                      '${price.toStringAsFixed(3)} ${ar ? 'د.ك' : 'KD'} · '
                      '${ar ? 'عمولة' : 'comm'} ${comm.toStringAsFixed(3)}',
                      style: const TextStyle(fontSize: 11,
                          fontWeight: FontWeight.w800)),
                  onTap: () {
                    setState(() => _lines.add({'product': m, 'qty': 1}));
                    Navigator.pop(ctx);
                  },
                );
              },
            )),
          ]),
        );
      }),
    );
  }

  Future<void> _submit() async {
    final ar = PartnersApi.instance.lang == 'ar';
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty
        || _lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
          ar ? 'أكمل اسم العميل + الهاتف + المنتجات'
             : 'Customer name + phone + items required')));
      return;
    }
    setState(() => _busy = true);
    try {
      await PartnersApi.instance.submitOrder(
        customerName: _name.text.trim(),
        customerPhone: _phone.text.trim(),
        area: _area.text.trim(),
        address: _address.text.trim(),
        note: _note.text.trim(),
        lines: [for (final l in _lines) {
          'product_id': (l['product'] as Map)['id'],
          'qty': l['qty'],
        }],
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = PartnersApi.instance.lang == 'ar';
    double total = 0, comm = 0;
    for (final l in _lines) {
      final m = l['product'] as Map;
      final qty = (l['qty'] as num).toDouble();
      total += (((m['price'] as Map?)?['amount'] as num?) ?? 0) * qty;
      comm += (((m['commission_amount'] as Map?)?['amount'] as num?) ?? 0)
          * qty;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(ar ? 'طلب جديد لعميلك' : 'New customer order',
            style: const TextStyle(fontWeight: FontWeight.w900,
                fontSize: 15)),
      ),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        _field(_name, ar ? 'اسم العميل *' : 'Customer name *'),
        _field(_phone, ar ? 'هاتف العميل *' : 'Customer phone *',
            keyboard: TextInputType.phone),
        _field(_area, ar ? 'المنطقة / المدينة' : 'Area / city'),
        _field(_address, ar ? 'تفاصيل العنوان' : 'Address details',
            lines: 2),
        _field(_note, ar ? 'ملاحظة للتوصيل' : 'Delivery note'),
        const SizedBox(height: 8),
        Row(children: [
          Text(ar ? 'المنتجات (${_lines.length})'
                  : 'Items (${_lines.length})',
              style: const TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w900)),
          const Spacer(),
          TextButton.icon(
            onPressed: _pickProduct,
            icon: const Icon(Icons.add, size: 16),
            label: Text(ar ? 'إضافة منتج' : 'Add item',
                style: const TextStyle(fontWeight: FontWeight.w800,
                    fontSize: 12)),
          ),
        ]),
        for (var i = 0; i < _lines.length; i++) _lineRow(i, ar),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Row(children: [
              Text(ar ? 'الإجمالي' : 'Total'),
              const Spacer(),
              Text('${total.toStringAsFixed(3)} ${ar ? 'د.ك' : 'KD'}',
                  style: const TextStyle(fontWeight: FontWeight.w900,
                      fontSize: 15, color: kDark)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Text(ar ? 'عمولتك المتوقعة' : 'Your est. commission',
                  style: const TextStyle(fontSize: 11.5,
                      color: Colors.grey)),
              const Spacer(),
              Text('+${comm.toStringAsFixed(3)}',
                  style: const TextStyle(fontWeight: FontWeight.w900,
                      fontSize: 13, color: kGreen)),
            ]),
          ]),
        ),
        const SizedBox(height: 14),
        ElevatedButton(
          onPressed: _busy ? null : _submit,
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15)),
          child: _busy
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5))
              : Text(ar ? '📨 إرسال للإدارة للمراجعة'
                        : '📨 Submit for review',
                  style: const TextStyle(fontSize: 14)),
        ),
        const SizedBox(height: 30),
      ]),
    );
  }

  Widget _field(TextEditingController c, String label,
      {TextInputType? keyboard, int lines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(
          controller: c, keyboardType: keyboard, maxLines: lines,
          decoration: InputDecoration(
            labelText: label, isDense: true,
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
      );

  Widget _lineRow(int i, bool ar) {
    final m = _lines[i]['product'] as Map;
    final qty = (_lines[i]['qty'] as num).toInt();
    final nm = (((m['name'] as Map?)?[ar ? 'ar' : 'en'])
        ?? (m['name'] as Map?)?['en'] ?? '').toString();
    final price = ((m['price'] as Map?)?['amount'] as num?) ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Expanded(child: Text(nm, maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12,
                fontWeight: FontWeight.w700))),
        Text(price.toStringAsFixed(3), style: const TextStyle(
            fontSize: 11.5, fontWeight: FontWeight.w800, color: kDark)),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => setState(() {
            if (qty > 1) _lines[i]['qty'] = qty - 1;
          }),
          child: const Icon(Icons.remove_circle_outline, size: 20,
              color: Colors.grey),
        ),
        SizedBox(width: 26, child: Text('$qty',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900))),
        GestureDetector(
          onTap: () => setState(() => _lines[i]['qty'] = qty + 1),
          child: const Icon(Icons.add_circle_outline, size: 20,
              color: kDark),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => setState(() => _lines.removeAt(i)),
          child: const Icon(Icons.delete_outline, size: 19,
              color: Colors.redAccent),
        ),
      ]),
    );
  }
}
