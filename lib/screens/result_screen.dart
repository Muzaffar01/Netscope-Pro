import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:netscope/providers/search_provider.dart';
import 'package:netscope/providers/theme_provider.dart';
import 'package:netscope/theme/app_theme.dart';
import 'package:netscope/widgets/domain_info_card.dart';
import 'package:netscope/widgets/server_info_card.dart';
import 'package:netscope/widgets/dns_records_card.dart';
import 'package:netscope/widgets/whois_info_card.dart';
import 'package:netscope/widgets/ping_card.dart';
import 'package:netscope/widgets/traceroute_graph.dart';
import 'package:netscope/widgets/latency_chart.dart';
import 'package:netscope/widgets/traceroute_map.dart';
import 'package:netscope/widgets/traceroute_detail_view.dart';

class ResultScreen extends StatefulWidget {
  final int initialTabIndex;
  
  const ResultScreen({super.key, this.initialTabIndex = 0});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTabIndex);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = context.watch<SearchProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;
    final info = searchProvider.websiteInfo;

    if (info == null) {
      return const Scaffold(
        body: Center(child: Text('No data available')),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            floating: false,
            backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCard.withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkCard.withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: const Icon(Icons.share_rounded, size: 18),
                ),
                onPressed: () {
                  final domain = searchProvider.currentDomain;
                  Share.share(
                    'Check out the analysis of $domain on NetScope!\n'
                    'Server: ${info.serverInfo?.ip ?? "N/A"}\n'
                    'Location: ${info.serverInfo?.city ?? "N/A"}, ${info.serverInfo?.country ?? "N/A"}\n'
                    'Ping: ${info.pingMs?.toStringAsFixed(1) ?? "N/A"}ms',
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 56),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    searchProvider.currentDomain,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${info.serverInfo?.ip ?? "N/A"} • ${info.serverInfo?.city ?? "Unknown"}, ${info.serverInfo?.countryCode ?? ""}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          // Tab bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              isDark: isDark,
              tabBar: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.primary,
                unselectedLabelColor: isDark ? Colors.white38 : Colors.black38,
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 3,
                labelStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Network'),
                  Tab(text: 'Traceroute'),
                  Tab(text: 'DNS & WHOIS'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(info, isDark),
            _buildNetworkTab(info, isDark),
            _buildTracerouteTab(info, isDark),
            _buildDnsWhoisTab(info, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(dynamic info, bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        if (info.domainInfo != null)
          DomainInfoCard(info: info.domainInfo!)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideX(begin: -0.1),
        const SizedBox(height: 12),
        if (info.serverInfo != null)
          ServerInfoCard(info: info.serverInfo!)
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms)
              .slideX(begin: -0.1),
        const SizedBox(height: 12),
        PingCard(
          pingMs: info.pingMs,
          serverIp: info.serverInfo?.ip,
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms)
            .slideX(begin: -0.1),
        const SizedBox(height: 12),
        if (info.traceroute != null)
          LatencyChart(traceroute: info.traceroute!)
              .animate()
              .fadeIn(delay: 300.ms, duration: 400.ms)
              .slideX(begin: -0.1),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildNetworkTab(dynamic info, bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        if (info.traceroute != null) ...[
          TracerouteGraph(traceroute: info.traceroute!)
              .animate()
              .fadeIn(duration: 400.ms),
          const SizedBox(height: 16),
          TracerouteMap(traceroute: info.traceroute!)
              .animate()
              .fadeIn(delay: 150.ms, duration: 400.ms),
        ] else
          _buildEmptyState('No traceroute data available', isDark),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildTracerouteTab(dynamic info, bool isDark) {
    if (info.traceroute != null && info.traceroute!.hops.isNotEmpty) {
      return TracerouteDetailView(traceroute: info.traceroute!);
    }
    return Center(child: _buildEmptyState('No traceroute data available', isDark));
  }

  Widget _buildDnsWhoisTab(dynamic info, bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        if (info.dnsRecords.isNotEmpty)
          DnsRecordsCard(records: info.dnsRecords)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideX(begin: -0.1),
        const SizedBox(height: 12),
        if (info.whoisInfo != null)
          WhoisInfoCard(info: info.whoisInfo!)
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms)
              .slideX(begin: -0.1)
        else
          _buildEmptyState('No WHOIS data available', isDark),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildEmptyState(String message, bool isDark) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 40,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;

  _TabBarDelegate({required this.tabBar, required this.isDark});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: isDark ? AppColors.darkBg : AppColors.lightBg,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
