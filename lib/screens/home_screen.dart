// Partner home — board / products / orders / wallet (standalone app).
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../api.dart';
import '../main.dart';
import 'login_screen.dart';
import 'order_composer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _me;
  bool _error = false;
  int _tab = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final me = await PartnersApi.instance.me();
      if (mounted) setState(() { _me = me; _error = false; });
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  Future<void> _logout() async {
    await PartnersApi.instance.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final ar = PartnersApi.instance.lang == 'ar';
    return Scaffold(
      appBar: AppBar(
        title: Text(ar ? '🤝 شركاء يلو' : '🤝 Uellow Partners',
            style: const TextStyle(fontWeight: FontWeight.w900,
                fontSize: 16)),
        actions: [
          IconButton(
            tooltip: ar ? 'تحديث' : 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'EN/AR',
            onPressed: () async {
              await PartnersApi.instance.setLang(ar ? 'en' : 'ar');
              PartnersApp.of(context)?.rebuild();
            },
            icon: const Icon(Icons.translate),
          ),
          IconButton(
            tooltip: ar ? 'خروج' : 'Sign out',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _body(ar),
    );
  }

  Widget _body(bool ar) {
    if (_error) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_outlined, size: 56, color: Colors.grey),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _load,
            child: Text(ar ? 'إعادة المحاولة' : 'Retry')),
      ]));
    }
    final me = _me;
    if (me == null) {
      return const Center(child: CircularProgressIndicator(color: kDark));
    }
    final status = (me['status'] ?? 'none').toString();
    if (status == 'none') return _JoinPitch(onDone: _load);
    if (status == 'pending') {
      return Center(child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('⏳', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Text(ar ? 'طلبك قيد المراجعة' : 'Application under review',
              style: const TextStyle(fontSize: 17,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(ar
              ? 'ستفعّل إدارة يلو حسابك قريباً — كودك: ${me['code']}'
              : 'Uellow will activate you soon — code: ${me['code']}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: _load,
              child: Text(ar ? 'تحقق الآن' : 'Check now')),
        ]),
      ));
    }
    if (status == 'suspended') {
      return Center(child: Padding(
        padding: const EdgeInsets.all(36),
        child: Text(ar ? 'حسابك موقوف — تواصل مع إدارة يلو'
                       : 'Account suspended — contact Uellow',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16,
                fontWeight: FontWeight.w900)),
      ));
    }
    return Column(children: [
      Container(
        color: Colors.white,
        child: Row(children: [
          for (final (i, label, icon) in [
            (0, ar ? 'لوحتي' : 'Board', Icons.dashboard_outlined),
            (1, ar ? 'منتجاتي' : 'Products', Icons.sell_outlined),
            (2, ar ? 'طلباتي' : 'Orders', Icons.receipt_long_outlined),
            (3, ar ? 'محفظتي' : 'Wallet',
                Icons.account_balance_wallet_outlined),
          ]) Expanded(child: InkWell(
            onTap: () => setState(() => _tab = i),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(
                color: _tab == i ? kGold : Colors.transparent, width: 2.5,
              ))),
              child: Column(children: [
                Icon(icon, size: 18,
                    color: _tab == i ? kDark : Colors.grey),
                Text(label, style: TextStyle(fontSize: 10.5,
                    fontWeight:
                        _tab == i ? FontWeight.w900 : FontWeight.w600,
                    color: _tab == i ? kDark : Colors.grey)),
              ]),
            ),
          )),
        ]),
      ),
      Expanded(child: switch (_tab) {
        1 => const ProductsTab(),
        2 => OrdersTab(onChanged: _load),
        3 => WalletTab(me: me, onChanged: _load),
        _ => DashboardTab(me: me),
      }),
    ]);
  }
}

// ─── join pitch ───────────────────────────────────────────────────────

class _JoinPitch extends StatelessWidget {
  const _JoinPitch({required this.onDone});
  final VoidCallback onDone;
  @override
  Widget build(BuildContext context) {
    final ar = PartnersApi.instance.lang == 'ar';
    return ListView(padding: const EdgeInsets.all(18), children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [kDark, Color(0xFF7A4A08)]),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(children: [
          const Text('🤝', style: TextStyle(fontSize: 46)),
          Text(ar ? 'اربح مع يلو' : 'Earn with Uellow',
              style: const TextStyle(color: kGoldLight, fontSize: 20,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(ar
              ? 'بِع منتجات يلو واربح عمولة على كل طلب ناجح'
              : 'Sell Uellow products & earn on every delivered order',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70,
                  fontSize: 12.5)),
        ]),
      ),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: () async {
          try {
            await PartnersApi.instance.apply();
            onDone();
          } on ApiException catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(e.message)));
            }
          }
        },
        style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15)),
        child: Text(ar ? 'قدّم طلب انضمام الآن' : 'Apply now',
            style: const TextStyle(fontSize: 14)),
      ),
    ]);
  }
}

// ─── dashboard ────────────────────────────────────────────────────────

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key, required this.me});
  final Map<String, dynamic> me;

  String _fmt(Map? m) =>
      '${((m?['amount'] as num?) ?? 0).toStringAsFixed(3)} '
      '${PartnersApi.instance.lang == 'ar' ? 'د.ك' : (m?['symbol'] ?? 'KD')}';

  @override
  Widget build(BuildContext context) {
    final ar = PartnersApi.instance.lang == 'ar';
    final tier = (me['tier'] ?? 'bronze').toString();
    final tierEmoji = {'bronze': '🥉', 'silver': '🥈', 'gold': '🥇',
        'platinum': '💎'}[tier] ?? '🥉';
    final next = (me['next_tier'] as Map?)?.cast<String, dynamic>();
    final link = ((me['links'] as Map?)?['short']
        ?? (me['links'] as Map?)?['web'] ?? '').toString();
    return ListView(padding: const EdgeInsets.all(14), children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [kDark, Color(0xFF6B4A1B)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ar ? 'كود الشريك' : 'Partner code',
                style: const TextStyle(color: Colors.white60,
                    fontSize: 11)),
            Text((me['code'] ?? '').toString(), style: const TextStyle(
                color: kGoldLight, fontSize: 24,
                fontWeight: FontWeight.w900, letterSpacing: 2)),
            Text('$tierEmoji ${tier.toUpperCase()} · ×${me['tier_multiplier'] ?? 1}',
                style: const TextStyle(color: Colors.white70,
                    fontSize: 11, fontWeight: FontWeight.w700)),
          ])),
          Column(children: [
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: link));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    duration: const Duration(seconds: 1),
                    content: Text(ar ? 'نُسخ الرابط' : 'Link copied')));
              },
              icon: const Icon(Icons.copy, color: kGoldLight),
            ),
            IconButton(
              onPressed: () => Share.share(ar
                  ? 'تسوّق من يلو عبر رابطي 🛍️\n$link'
                  : 'Shop Uellow through my link 🛍️\n$link'),
              icon: const Icon(Icons.share, color: kGoldLight),
            ),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      Row(children: [
        _stat(ar ? 'متاح للسحب' : 'Available',
            _fmt(me['available'] as Map?), kGreen),
        const SizedBox(width: 8),
        _stat(ar ? 'قيد التوصيل' : 'Pending',
            _fmt(me['pending'] as Map?), const Color(0xFFB8860B)),
        const SizedBox(width: 8),
        _stat(ar ? 'مدفوع' : 'Paid', _fmt(me['paid'] as Map?), Colors.grey),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        _stat(ar ? 'عمولة الشهر' : 'This month',
            _fmt(me['month_commission'] as Map?), kDark),
        const SizedBox(width: 8),
        _stat(ar ? 'إجمالي المبيعات' : 'Total sales',
            _fmt(me['total_sales'] as Map?), kDark),
        const SizedBox(width: 8),
        _stat(ar ? 'فتحات الرابط' : 'Link opens',
            '${me['click_count'] ?? 0}', kDark),
      ]),
      if (next != null) ...[
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(ar
                ? 'الترقية إلى ${next['tier']} عند ${next['needed']} د.ك مبيعات شهرية'
                : 'Reach ${next['needed']} KD monthly for ${next['tier']}',
                style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ((next['progress'] as num?) ?? 0).toDouble(),
                minHeight: 9,
                backgroundColor: const Color(0xFFEFEFEF),
                color: kGold,
              ),
            ),
          ]),
        ),
      ],
      const SizedBox(height: 14),
      const LeaderboardCard(),
    ]);
  }

  Widget _stat(String label, String value, Color color) =>
      Expanded(child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          FittedBox(child: Text(value, style: TextStyle(fontSize: 14,
              fontWeight: FontWeight.w900, color: color))),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 9.5,
              color: Colors.grey, fontWeight: FontWeight.w700)),
        ]),
      ));
}

class LeaderboardCard extends StatefulWidget {
  const LeaderboardCard({super.key});
  @override
  State<LeaderboardCard> createState() => _LeaderboardCardState();
}

class _LeaderboardCardState extends State<LeaderboardCard> {
  Map<String, dynamic>? _data;
  @override
  void initState() {
    super.initState();
    PartnersApi.instance.leaderboard().then((d) {
      if (mounted) setState(() => _data = d);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final ar = PartnersApi.instance.lang == 'ar';
    final top = List<Map<String, dynamic>>.from(
        (_data?['top'] as List?) ?? const []);
    if (top.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(ar ? '🏆 متصدرو الشهر' : '🏆 Monthly leaderboard',
            style: const TextStyle(fontSize: 13,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        for (final r in top) Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            SizedBox(width: 26, child: Text(
                ['🥇', '🥈', '🥉'].elementAtOrNull(
                    ((r['rank'] as num?) ?? 4).toInt() - 1)
                    ?? '${r['rank']}.',
                style: const TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w800))),
            Expanded(child: Text((r['name'] ?? '').toString(),
                style: TextStyle(fontSize: 12,
                    fontWeight: r['me'] == true
                        ? FontWeight.w900 : FontWeight.w600))),
            Text('${(((r['amount'] as Map?)?['amount'] as num?) ?? 0).toStringAsFixed(3)} ${ar ? 'د.ك' : 'KD'}',
                style: const TextStyle(fontSize: 11.5,
                    fontWeight: FontWeight.w800, color: kGreen)),
          ]),
        ),
        if (_data?['my_rank'] != null)
          Text(ar ? 'ترتيبك: #${_data!['my_rank']}'
                  : 'Your rank: #${_data!['my_rank']}',
              style: const TextStyle(fontSize: 11, color: Colors.grey,
                  fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

// ─── products tab ─────────────────────────────────────────────────────

class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});
  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  List<Map<String, dynamic>>? _items;
  final _q = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final v = await PartnersApi.instance.products(q: _q.text.trim());
      if (mounted) setState(() => _items = v);
    } catch (_) {
      if (mounted) setState(() => _items = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = PartnersApi.instance.lang == 'ar';
    final items = _items;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: TextField(
          controller: _q,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _load(),
          decoration: InputDecoration(
            hintText: ar ? 'ابحث في كتالوجك…' : 'Search your catalog…',
            prefixIcon: const Icon(Icons.search, size: 18),
            isDense: true, filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
      ),
      Expanded(child: items == null
          ? const Center(child: CircularProgressIndicator(color: kDark))
          : items.isEmpty
              ? Center(child: Text(ar ? 'لا توجد منتجات بعد'
                                      : 'No products yet'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 20),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _row(items[i], ar),
                )),
    ]);
  }

  Widget _row(Map<String, dynamic> m, bool ar) {
    final name = (((m['name'] as Map?)?[ar ? 'ar' : 'en'])
        ?? (m['name'] as Map?)?['en'] ?? '').toString();
    final img = (m['image'] as String?) ?? '';
    final price = ((m['price'] as Map?)?['amount'] as num?) ?? 0;
    final commPct = (m['commission_pct'] as num?) ?? 0;
    final commAmt =
        ((m['commission_amount'] as Map?)?['amount'] as num?) ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
              imageUrl: img.startsWith('http')
                  ? img : '${PartnersApi.baseUrl}$img',
              width: 64, height: 64, fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  const ColoredBox(color: Color(0xFFEFEFEF))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Row(children: [
            Text('${price.toStringAsFixed(3)} ${ar ? 'د.ك' : 'KD'}',
                style: const TextStyle(fontSize: 12.5,
                    fontWeight: FontWeight.w900, color: kDark)),
            const SizedBox(width: 8),
            Flexible(child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F7EF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                  ar ? 'عمولتك ${commAmt.toStringAsFixed(3)} (${commPct.toStringAsFixed(1)}%)'
                     : 'Earn ${commAmt.toStringAsFixed(3)} (${commPct.toStringAsFixed(1)}%)',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9.5,
                      fontWeight: FontWeight.w900, color: kGreen)),
            )),
          ]),
        ])),
        IconButton(
          onPressed: () => Share.share((m['share_text'] ?? '').toString()),
          icon: const Icon(Icons.share, size: 20, color: kDark),
        ),
      ]),
    );
  }
}

// ─── orders tab ───────────────────────────────────────────────────────

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key, required this.onChanged});
  final VoidCallback onChanged;
  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  List<Map<String, dynamic>>? _orders;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final v = await PartnersApi.instance.orders();
      if (mounted) setState(() => _orders = v);
    } catch (_) {
      if (mounted) setState(() => _orders = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = PartnersApi.instance.lang == 'ar';
    final orders = _orders;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kGold, foregroundColor: kDark,
        onPressed: () async {
          final ok = await Navigator.push<bool>(context,
              MaterialPageRoute(builder: (_) => const OrderComposer()));
          if (ok == true) { _load(); widget.onChanged(); }
        },
        icon: const Icon(Icons.add),
        label: Text(ar ? 'طلب جديد' : 'New order',
            style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: orders == null
          ? const Center(child: CircularProgressIndicator(color: kDark))
          : orders.isEmpty
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Text(
                      ar ? 'سجّل أول طلب لعميلك —\nبعد الموافقة والتسليم تنزل عمولتك تلقائياً'
                         : 'Create your first order — commission books after approval + delivery',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey))))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 90),
                  itemCount: orders.length,
                  itemBuilder: (_, i) => _card(orders[i], ar),
                ),
    );
  }

  Widget _card(Map<String, dynamic> o, bool ar) {
    final state = (o['state'] ?? '').toString();
    final (chipBg, chipFg, label) = switch (state) {
      'submitted' => (const Color(0xFFFFF3D6), const Color(0xFF8B6508),
          ar ? '📨 قيد المراجعة' : '📨 Under review'),
      'approved' => (const Color(0xFFE6F7EF), kGreen,
          ar ? '✅ مقبول' : '✅ Approved'),
      'rejected' => (const Color(0xFFFDE8E8), const Color(0xFFC0392B),
          ar ? '❌ مرفوض' : '❌ Rejected'),
      _ => (const Color(0xFFEFEFEF), Colors.grey,
          ar ? 'مسودة' : 'Draft'),
    };
    final total = ((o['total'] as Map?)?['amount'] as num?) ?? 0;
    final comm = ((o['commission'] as Map?)?['amount'] as num?) ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text((o['name'] ?? '').toString(), style: const TextStyle(
              fontWeight: FontWeight.w900, fontSize: 13)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: chipBg,
                borderRadius: BorderRadius.circular(999)),
            child: Text(label, style: TextStyle(fontSize: 10,
                fontWeight: FontWeight.w900, color: chipFg)),
          ),
        ]),
        const SizedBox(height: 6),
        Text('${o['customer_name']} · ${o['customer_phone']}',
            style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
        const SizedBox(height: 6),
        Row(children: [
          Text('${total.toStringAsFixed(3)} ${ar ? 'د.ك' : 'KD'}',
              style: const TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w900, color: kDark)),
          const SizedBox(width: 10),
          Text(ar ? 'عمولتك: ${comm.toStringAsFixed(3)}'
                  : 'Commission: ${comm.toStringAsFixed(3)}',
              style: const TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w800, color: kGreen)),
        ]),
      ]),
    );
  }
}

// ─── wallet tab ───────────────────────────────────────────────────────

class WalletTab extends StatefulWidget {
  const WalletTab({super.key, required this.me, required this.onChanged});
  final Map<String, dynamic> me;
  final VoidCallback onChanged;
  @override
  State<WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends State<WalletTab> {
  List<Map<String, dynamic>>? _comms;
  List<Map<String, dynamic>>? _payouts;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final c = await PartnersApi.instance.commissions();
      final p = await PartnersApi.instance.payouts();
      if (mounted) setState(() { _comms = c; _payouts = p; });
    } catch (_) {
      if (mounted) setState(() { _comms = const []; _payouts = const []; });
    }
  }

  Future<void> _requestPayout() async {
    final ar = PartnersApi.instance.lang == 'ar';
    final available =
        (((widget.me['available'] as Map?)?['amount'] as num?) ?? 0)
            .toDouble();
    final minPayout = ((widget.me['min_payout'] as num?) ?? 5).toDouble();
    final amountCtrl =
        TextEditingController(text: available.toStringAsFixed(3));
    var method = (widget.me['payout_method'] ?? 'wallet').toString();
    final detailsCtrl = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius:
          BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) =>
        Padding(
          padding: EdgeInsets.fromLTRB(18, 16, 18,
              18 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ar ? '💸 طلب سحب' : '💸 Request payout',
                style: const TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w900)),
            Text(ar
                ? 'المتاح: ${available.toStringAsFixed(3)} · الحد الأدنى ${minPayout.toStringAsFixed(3)}'
                : 'Available: ${available.toStringAsFixed(3)} · min ${minPayout.toStringAsFixed(3)}',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              decoration: InputDecoration(
                  labelText: ar ? 'المبلغ' : 'Amount',
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            Wrap(spacing: 8, children: [
              for (final m in [
                ('wallet', ar ? '👛 محفظة يلو' : '👛 Wallet'),
                ('knet', '💳 KNET'),
                ('bank', ar ? '🏦 بنك' : '🏦 Bank'),
              ]) ChoiceChip(
                label: Text(m.$2, style: const TextStyle(fontSize: 12)),
                selected: method == m.$1,
                onSelected: (_) => setSheet(() => method = m.$1),
              ),
            ]),
            if (method != 'wallet') Padding(
              padding: const EdgeInsets.only(top: 10),
              child: TextField(
                controller: detailsCtrl,
                decoration: InputDecoration(
                    labelText: ar ? 'IBAN / رقم الهاتف' : 'IBAN / phone',
                    border: const OutlineInputBorder()),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13)),
              child: Text(ar ? 'إرسال الطلب' : 'Submit'),
            )),
          ]),
        )),
    );
    if (ok != true) return;
    try {
      await PartnersApi.instance.requestPayout(
        amount: double.tryParse(amountCtrl.text.trim()) ?? 0,
        method: method,
        details: detailsCtrl.text.trim(),
      );
      _load(); widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
            PartnersApi.instance.lang == 'ar'
                ? 'تم إرسال طلب السحب ✓' : 'Payout requested ✓')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = PartnersApi.instance.lang == 'ar';
    final comms = _comms;
    return ListView(padding: const EdgeInsets.fromLTRB(12, 10, 12, 30),
        children: [
      SizedBox(width: double.infinity, child: ElevatedButton.icon(
        onPressed: _requestPayout,
        icon: const Icon(Icons.account_balance_wallet_outlined, size: 17),
        label: Text(ar ? 'طلب سحب الأرباح' : 'Request payout'),
        style: ElevatedButton.styleFrom(
            backgroundColor: kDark, foregroundColor: kGoldLight,
            padding: const EdgeInsets.symmetric(vertical: 13)),
      )),
      if ((_payouts ?? const []).isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(ar ? 'طلبات السحب' : 'Payout requests',
            style: const TextStyle(fontSize: 13,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        for (final p in _payouts!) Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Text((p['name'] ?? '').toString(), style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 12)),
            const Spacer(),
            Text('${(((p['amount'] as Map?)?['amount'] as num?) ?? 0).toStringAsFixed(3)} ${ar ? 'د.ك' : 'KD'}',
                style: const TextStyle(fontWeight: FontWeight.w900,
                    fontSize: 12, color: kDark)),
            const SizedBox(width: 8),
            Text(switch ((p['state'] ?? '').toString()) {
              'paid' => '✅', 'rejected' => '❌', _ => '⏳',
            }),
          ]),
        ),
      ],
      const SizedBox(height: 12),
      Text(ar ? 'سجل العمولات' : 'Commission ledger',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      if (comms == null)
        const Center(child: Padding(padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(color: kDark)))
      else if (comms.isEmpty)
        Padding(padding: const EdgeInsets.all(20),
            child: Center(child: Text(
                ar ? 'لا توجد عمولات بعد — ابدأ بمشاركة منتجاتك!'
                   : 'No commissions yet — start sharing!',
                style: const TextStyle(color: Colors.grey))))
      else for (final c in comms) Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Text(switch ((c['source'] ?? '').toString()) {
            'link' => '🔗', 'submitted' => '📝',
            'bonus' => '🎁', _ => '✏️',
          }, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text((c['order'] ?? '').toString().isEmpty
                    ? (ar ? 'عمولة' : 'Commission')
                    : (c['order'] ?? '').toString(),
                style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w800)),
            Text(((c['date'] ?? '') as String).split('T').first,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ])),
          Text('+${(((c['amount'] as Map?)?['amount'] as num?) ?? 0).toStringAsFixed(3)}',
              style: const TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w900, color: kGreen)),
          const SizedBox(width: 8),
          Text(switch ((c['state'] ?? '').toString()) {
            'confirmed' => '✅', 'paid' => '💸',
            'cancelled' => '❌', _ => '⏳',
          }, style: const TextStyle(fontSize: 13)),
        ]),
      ),
    ]);
  }
}
