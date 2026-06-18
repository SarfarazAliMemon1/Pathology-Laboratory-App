import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/test_catalog_screen.dart';
import 'screens/new_order_screen.dart';
import 'screens/stock_screen.dart';
import 'screens/orders_list_screen.dart';
import 'screens/today_orders_screen.dart';
import 'screens/pending_results_screen.dart';
import 'screens/daily_expense_screen.dart';
import 'screens/today_revenue_screen.dart';
import 'screens/patient_report_screen.dart';
import '../models/order_model.dart';
import '../models/expense_model.dart';
import '../models/data_notifier.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('theme_mode');
    setState(() {
      if (theme == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.light;
      }
    });
  }

  void _toggleTheme() async {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', _themeMode == ThemeMode.dark ? 'dark' : 'light');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pathology Lab',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6366F1), brightness: Brightness.light),
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: Colors.grey.shade50,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6366F1), brightness: Brightness.dark),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: Colors.grey.shade900,
      ),
      home: MainScreen(toggleTheme: _toggleTheme, themeMode: _themeMode),
      routes: {
        '/test-catalog': (context) => const TestCatalogScreen(),
        '/new-order': (context) => const NewOrderScreen(),
        '/orders': (context) => const OrdersListScreen(),
        '/stock': (context) => const StockScreen(),
        '/today-orders': (context) => const TodayOrdersScreen(),
        '/pending-results': (context) => const PendingResultsScreen(),
        '/daily-expense': (context) => const DailyExpenseScreen(),
        '/today-revenue': (context) => const TodayRevenueScreen(),
        '/patient-report': (context) => const PatientReportScreen(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode themeMode;

  const MainScreen({super.key, required this.toggleTheme, required this.themeMode});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardScreen(toggleTheme: widget.toggleTheme, themeMode: widget.themeMode),
          const StockScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.inventory_outlined), label: 'Inventory'),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final ThemeMode themeMode;

  const DashboardScreen({super.key, required this.toggleTheme, required this.themeMode});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _todayOrdersCount = 0;
  int _pendingCount = 0;
  double _totalExpenses = 0.0;
  double _todayRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    _updateCounts();
    DataNotifier.setListener(_updateCounts);
  }

  @override
  void dispose() {
    DataNotifier.removeListener();
    super.dispose();
  }

  void _updateCounts() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayCount = OrderData.orders.where((order) {
      final orderDate = DateTime(order.orderDate.year, order.orderDate.month, order.orderDate.day);
      return orderDate == today;
    }).length;
    final pendingCount = OrderData.orders.where((order) => order.status == 'pending').length;
    final totalExp = ExpenseData.expenses.fold(0.0, (sum, e) => sum + e.amount);
    final revenue = OrderData.orders.where((order) {
      final orderDate = DateTime(order.orderDate.year, order.orderDate.month, order.orderDate.day);
      return orderDate == today && order.paymentStatus == 'paid';
    }).fold(0.0, (sum, order) => sum + order.totalAmount);

    setState(() {
      _todayOrdersCount = todayCount;
      _pendingCount = pendingCount;
      _totalExpenses = totalExp;
      _todayRevenue = revenue;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 1000 ? 4 : 2;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(widget.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.toggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _updateCounts,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Welcome Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFD946EF)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome Back!', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Here\'s your lab performance summary', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Grid with fixed card height regardless of window width
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 150,
              ),
              children: [
                _DashboardCard(
                  title: 'New Order',
                  value: null,
                  icon: Icons.add_shopping_cart,
                  color: const Color(0xFF6366F1),
                  isDark: isDark,
                  route: '/new-order',
                  onAfterTap: _updateCounts,
                ),
                _DashboardCard(
                  title: 'Lab Order',
                  value: null,
                  icon: Icons.receipt_long,
                  color: const Color(0xFFF59E0B),
                  isDark: isDark,
                  route: '/orders',
                  onAfterTap: _updateCounts,
                ),
                _DashboardCard(
                  title: 'Test Catalog',
                  value: null,
                  icon: Icons.science,
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                  route: '/test-catalog',
                  onAfterTap: _updateCounts,
                ),
                _DashboardCard(
                  title: 'Patient Report',
                  value: null,
                  icon: Icons.picture_as_pdf,
                  color: const Color(0xFFEF4444),
                  isDark: isDark,
                  route: '/patient-report',
                  onAfterTap: _updateCounts,
                ),
                _DashboardCard(
                  title: 'Today\'s Orders',
                  value: '$_todayOrdersCount',
                  icon: Icons.today,
                  color: const Color(0xFF3B82F6),
                  isDark: isDark,
                  route: '/today-orders',
                  onAfterTap: _updateCounts,
                ),
                _DashboardCard(
                  title: 'Daily Expense',
                  value: 'Rs ${_totalExpenses.toStringAsFixed(0)}',
                  icon: Icons.receipt,
                  color: const Color(0xFF8B5CF6),
                  isDark: isDark,
                  route: '/daily-expense',
                  onAfterTap: _updateCounts,
                ),
                _DashboardCard(
                  title: 'Pending Results',
                  value: '$_pendingCount',
                  icon: Icons.pending_actions,
                  color: const Color(0xFFEF4444),
                  isDark: isDark,
                  route: '/pending-results',
                  onAfterTap: _updateCounts,
                ),
                _DashboardCard(
                  title: 'Today\'s Revenue',
                  value: 'Rs ${_todayRevenue.toStringAsFixed(0)}',
                  icon: Icons.currency_rupee,
                  color: const Color(0xFF06B6D4),
                  isDark: isDark,
                  route: '/today-revenue',
                  onAfterTap: _updateCounts,
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatefulWidget {
  final String title;
  final String? value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final String? route;
  final VoidCallback? onAfterTap;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
    this.route,
    this.onAfterTap,
  });

  @override
  State<_DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<_DashboardCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = widget.isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    // Respect the OS "reduce motion" accessibility setting (Apple/Android).
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final motionDuration = reduceMotion ? Duration.zero : const Duration(milliseconds: 220);
    // iOS-style easing: gentle ease-out for a soft, settled landing.
    const motionCurve = Curves.easeOutCubic;
    final scale = (_isHovered && !reduceMotion) ? 1.03 : 1.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      // Scale is a GPU-friendly transform: the "lift" never reflows the grid.
      child: AnimatedScale(
        scale: scale,
        duration: motionDuration,
        curve: motionCurve,
        child: AnimatedContainer(
          duration: motionDuration,
          curve: motionCurve,
          decoration: BoxDecoration(
            color: widget.isDark ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: _isHovered
                ? [BoxShadow(color: widget.color.withOpacity(0.35), blurRadius: 20, spreadRadius: 1, offset: const Offset(0, 8))]
                : [BoxShadow(color: widget.color.withOpacity(0.15), blurRadius: 10, spreadRadius: 0, offset: const Offset(0, 3))],
            border: Border.all(
              color: _isHovered ? widget.color.withOpacity(0.45) : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                if (widget.route != null) {
                  Navigator.pushNamed(context, widget.route!).then((_) {
                    if (widget.onAfterTap != null) {
                      widget.onAfterTap!();
                    }
                    DataNotifier.notify();
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coming Soon!'), duration: Duration(seconds: 1)),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon at top
                    AnimatedContainer(
                      duration: motionDuration,
                      curve: motionCurve,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(_isHovered ? 0.22 : 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 22),
                    ),
                    const Spacer(), // pushes text to bottom
                    // Text at bottom
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.value != null)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.value!,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                                letterSpacing: -0.5,
                                height: 1.1,
                              ),
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                        const SizedBox(height: 3),
                        Flexible(
                          child: Text(
                            widget.title,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: mutedColor,
                              height: 1.15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
