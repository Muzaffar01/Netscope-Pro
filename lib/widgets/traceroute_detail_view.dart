import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netscope/models/website_info.dart';
import 'package:netscope/theme/app_theme.dart';

class TracerouteDetailView extends StatefulWidget {
  final TracerouteResult traceroute;

  const TracerouteDetailView({super.key, required this.traceroute});

  @override
  State<TracerouteDetailView> createState() => _TracerouteDetailViewState();
}

class _TracerouteDetailViewState extends State<TracerouteDetailView>
    with SingleTickerProviderStateMixin {
  int? _expandedHop;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hops = widget.traceroute.hops;
    final validHops = hops.where((h) => !h.isTimeout && h.ip != null).toList();
    final avgLatency = validHops.isNotEmpty
        ? validHops
            .where((h) => h.latency != null)
            .fold<double>(0, (sum, h) => sum + h.latency!) /
            validHops.where((h) => h.latency != null).length
        : 0.0;
    final maxLatency = validHops.isNotEmpty
        ? validHops
            .where((h) => h.latency != null)
            .fold<double>(0, (sum, h) => h.latency! > sum ? h.latency! : sum)
        : 0.0;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // Route summary header
        _buildRouteSummaryCard(isDark, hops, validHops, avgLatency, maxLatency),
        const SizedBox(height: 16),

        // Destination info
        _buildDestinationCard(isDark),
        const SizedBox(height: 20),

        // Section title
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primary, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Route Path',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${hops.length} hops',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

        // Hop timeline
        ...List.generate(hops.length, (index) {
          final hop = hops[index];
          final isFirst = index == 0;
          final isLast = index == hops.length - 1;
          final isExpanded = _expandedHop == index;

          return _buildHopTimelineItem(
            hop,
            isDark,
            isFirst,
            isLast,
            isExpanded,
            index,
            hops.length,
          ).animate().fadeIn(
                delay: Duration(milliseconds: 250 + index * 60),
                duration: 400.ms,
              ).slideX(begin: 0.05);
        }),

        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildRouteSummaryCard(
    bool isDark,
    List<TracerouteHop> hops,
    List<TracerouteHop> validHops,
    double avgLatency,
    double maxLatency,
  ) {
    final timeouts = hops.where((h) => h.isTimeout).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.accent.withValues(alpha: 0.08),
                ]
              : [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.accent.withValues(alpha: 0.04),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.route_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Route Analysis',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Network path to destination',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatChip(
                Icons.linear_scale_rounded,
                '${hops.length}',
                'Total Hops',
                AppColors.primary,
                isDark,
              ),
              const SizedBox(width: 10),
              _buildStatChip(
                Icons.speed_rounded,
                '${avgLatency.toStringAsFixed(1)}ms',
                'Avg Latency',
                AppColors.success,
                isDark,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStatChip(
                Icons.trending_up_rounded,
                '${maxLatency.toStringAsFixed(1)}ms',
                'Max Latency',
                AppColors.warning,
                isDark,
              ),
              const SizedBox(width: 10),
              _buildStatChip(
                Icons.error_outline_rounded,
                '$timeouts',
                'Timeouts',
                timeouts > 0 ? AppColors.error : AppColors.success,
                isDark,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05);
  }

  Widget _buildStatChip(
    IconData icon,
    String value,
    String label,
    Color color,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.dns_rounded, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Destination',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white38 : Colors.black38,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.traceroute.destination.isNotEmpty
                      ? widget.traceroute.destination
                      : 'Unknown',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.traceroute.destinationIp.isNotEmpty
                  ? widget.traceroute.destinationIp
                  : 'N/A',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }

  Widget _buildHopTimelineItem(
    TracerouteHop hop,
    bool isDark,
    bool isFirst,
    bool isLast,
    bool isExpanded,
    int index,
    int totalHops,
  ) {
    final latencyColor = hop.latency != null
        ? AppColors.getLatencyColor(hop.latency!)
        : (hop.isTimeout ? AppColors.error : Colors.grey);

    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedHop = isExpanded ? null : index;
        });
      },
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline track
            SizedBox(
              width: 56,
              child: Column(
                children: [
                  // Top connector line
                  if (!isFirst)
                    Expanded(
                      flex: 1,
                      child: Container(
                        width: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _getHopLineColor(index - 1, totalHops),
                              _getHopLineColor(index, totalHops),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Hop node circle
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final showPulse = isLast && !hop.isTimeout;
                      return Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          border: Border.all(
                            color: latencyColor,
                            width: 3,
                          ),
                          boxShadow: [
                            if (showPulse)
                              BoxShadow(
                                color: latencyColor.withValues(
                                    alpha: 0.3 + _pulseController.value * 0.2),
                                blurRadius: 8 + _pulseController.value * 6,
                                spreadRadius: _pulseController.value * 3,
                              ),
                            BoxShadow(
                              color: latencyColor.withValues(alpha: 0.15),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Center(
                          child: hop.isTimeout
                              ? Icon(Icons.close_rounded,
                                  size: 16, color: latencyColor)
                              : isFirst
                                  ? Icon(Icons.computer_rounded,
                                      size: 14, color: latencyColor)
                                  : isLast
                                      ? Icon(Icons.cloud_rounded,
                                          size: 14, color: latencyColor)
                                      : Text(
                                          '${hop.hop}',
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: latencyColor,
                                          ),
                                        ),
                        ),
                      );
                    },
                  ),

                  // Bottom connector line
                  if (!isLast)
                    Expanded(
                      flex: 1,
                      child: Container(
                        width: 3,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _getHopLineColor(index, totalHops),
                              _getHopLineColor(index + 1, totalHops),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Hop content card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? (isExpanded
                            ? AppColors.darkCard
                            : AppColors.darkCard.withValues(alpha: 0.6))
                        : (isExpanded
                            ? AppColors.lightCard
                            : AppColors.lightCard.withValues(alpha: 0.8)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isExpanded
                          ? latencyColor.withValues(alpha: 0.4)
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: isExpanded ? 1.5 : 1,
                    ),
                    boxShadow: isExpanded
                        ? [
                            BoxShadow(
                              color: latencyColor.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main row
                      Row(
                        children: [
                          // IP / Timeout label
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      hop.isTimeout
                                          ? 'Request timed out'
                                          : (hop.ip ?? 'Unknown'),
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: hop.isTimeout
                                            ? (isDark
                                                ? Colors.white24
                                                : Colors.black26)
                                            : null,
                                      ),
                                    ),
                                    if (isFirst) ...[
                                      const SizedBox(width: 6),
                                      _buildBadge('START', AppColors.primary, isDark),
                                    ],
                                    if (isLast && !hop.isTimeout) ...[
                                      const SizedBox(width: 6),
                                      _buildBadge('DEST', AppColors.accent, isDark),
                                    ],
                                  ],
                                ),
                                if (hop.hostname != null &&
                                    hop.hostname!.isNotEmpty &&
                                    hop.hostname != hop.ip) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    hop.hostname!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.white30 : Colors.black26,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Latency chip
                          if (hop.latency != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: latencyColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: latencyColor.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: latencyColor,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${hop.latency!.toStringAsFixed(1)} ms',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: latencyColor,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (hop.isTimeout)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '* * *',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error.withValues(alpha: 0.6),
                                ),
                              ),
                            ),

                          const SizedBox(width: 6),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                        ],
                      ),

                      // Expanded detail section
                      if (isExpanded) ...[
                        const SizedBox(height: 14),
                        Container(
                          height: 1,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.04),
                        ),
                        const SizedBox(height: 14),
                        _buildDetailGrid(hop, isDark, isFirst, isLast),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDetailGrid(
    TracerouteHop hop,
    bool isDark,
    bool isFirst,
    bool isLast,
  ) {
    final details = <_DetailItem>[];

    details.add(_DetailItem(
      icon: Icons.tag_rounded,
      label: 'Hop #',
      value: '${hop.hop}',
    ));

    details.add(_DetailItem(
      icon: Icons.lan_rounded,
      label: 'IP Address',
      value: hop.ip ?? (hop.isTimeout ? 'Timed out' : 'N/A'),
    ));

    if (hop.hostname != null && hop.hostname!.isNotEmpty) {
      details.add(_DetailItem(
        icon: Icons.dns_rounded,
        label: 'Hostname',
        value: hop.hostname!,
      ));
    }

    details.add(_DetailItem(
      icon: Icons.timer_rounded,
      label: 'Latency',
      value: hop.latency != null ? '${hop.latency!.toStringAsFixed(2)} ms' : 'N/A',
    ));

    if (hop.city != null && hop.city!.isNotEmpty) {
      details.add(_DetailItem(
        icon: Icons.location_city_rounded,
        label: 'City',
        value: hop.city!,
      ));
    }

    if (hop.country != null && hop.country!.isNotEmpty) {
      details.add(_DetailItem(
        icon: Icons.flag_rounded,
        label: 'Country',
        value: '${hop.country!}${hop.countryCode != null ? ' (${hop.countryCode})' : ''}',
      ));
    }

    if (hop.latitude != null && hop.longitude != null) {
      details.add(_DetailItem(
        icon: Icons.my_location_rounded,
        label: 'Coordinates',
        value:
            '${hop.latitude!.toStringAsFixed(4)}, ${hop.longitude!.toStringAsFixed(4)}',
      ));
    }

    details.add(_DetailItem(
      icon: Icons.info_outline_rounded,
      label: 'Status',
      value: hop.isTimeout
          ? 'Timed Out'
          : isFirst
              ? 'Origin Gateway'
              : isLast
                  ? 'Final Destination'
                  : 'Transit Node',
    ));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: details.map((d) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 110) / 2,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  d.icon,
                  size: 14,
                  color: AppColors.primary.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white30 : Colors.black26,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        d.value,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getHopLineColor(int index, int total) {
    if (total <= 1) return AppColors.primary;
    final t = index / (total - 1);
    return Color.lerp(AppColors.primary, AppColors.accent, t) ?? AppColors.primary;
  }
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;

  _DetailItem({required this.icon, required this.label, required this.value});
}
