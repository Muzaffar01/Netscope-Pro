import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:netscope/models/website_info.dart';
import 'package:netscope/providers/theme_provider.dart';
import 'package:netscope/theme/app_theme.dart';

class TracerouteGraph extends StatefulWidget {
  final TracerouteResult traceroute;

  const TracerouteGraph({super.key, required this.traceroute});

  @override
  State<TracerouteGraph> createState() => _TracerouteGraphState();
}

class _TracerouteGraphState extends State<TracerouteGraph>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int? _selectedHop;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final hops = widget.traceroute.hops;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.accent.withValues(alpha: 0.04),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.route_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NETWORK ROUTE',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${hops.length} hops to ${widget.traceroute.destination}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                ),
                // Legend
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _legendDot(AppColors.latencyExcellent, '<20ms'),
                    const SizedBox(width: 8),
                    _legendDot(AppColors.latencyAverage, '50-100'),
                    const SizedBox(width: 8),
                    _legendDot(AppColors.latencyBad, '>200'),
                  ],
                ),
              ],
            ),
          ),

          // Graph
          SizedBox(
            height: max(hops.length * 88.0 + 24, 200),
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                return CustomPaint(
                  size: Size(double.infinity, max(hops.length * 88.0 + 24, 200)),
                  painter: _TracerouteNodePainter(
                    hops: hops,
                    isDark: isDark,
                    animValue: _animController.value,
                    selectedHop: _selectedHop,
                  ),
                  child: _buildInteractiveNodes(hops, isDark),
                );
              },
            ),
          ),

          // Selected node details
          if (_selectedHop != null)
            _buildHopDetails(hops[_selectedHop!], isDark),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildInteractiveNodes(List<TracerouteHop> hops, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: List.generate(hops.length, (index) {
          final hop = hops[index];
          final latencyColor = hop.latency != null
              ? AppColors.getLatencyColor(hop.latency!)
              : Colors.grey;
          final bool isSelected = _selectedHop == index;

          return GestureDetector(
            onTap: () => setState(() {
              _selectedHop = _selectedHop == index ? null : index;
            }),
            child: SizedBox(
              height: 88,
              child: Row(
                children: [
                  // Hop number
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${hop.hop}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.3),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Node indicator
                  Column(
                    children: [
                      if (index > 0)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: latencyColor.withValues(alpha: 0.3),
                          ),
                        ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isSelected ? 20 : 14,
                        height: isSelected ? 20 : 14,
                        decoration: BoxDecoration(
                          color: hop.isTimeout
                              ? Colors.grey.withValues(alpha: 0.3)
                              : latencyColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : latencyColor.withValues(alpha: 0.5),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            if (!hop.isTimeout)
                              BoxShadow(
                                color: latencyColor.withValues(alpha: 0.4),
                                blurRadius: isSelected ? 12 : 6,
                                spreadRadius: isSelected ? 2 : 0,
                              ),
                          ],
                        ),
                      ),
                      if (index < hops.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: latencyColor.withValues(alpha: 0.3),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(width: 14),

                  // Node details
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? latencyColor.withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(
                                color: latencyColor.withValues(alpha: 0.2))
                            : null,
                      ),
                      child: hop.isTimeout
                          ? Text(
                              '* * * Request timed out',
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: isDark ? Colors.white24 : Colors.black12,
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        hop.hostname ?? hop.ip ?? 'Unknown',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (hop.latency != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: latencyColor
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${hop.latency!.toStringAsFixed(1)}ms',
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: latencyColor,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (hop.ip != null)
                                      Text(
                                        hop.ip!,
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 11,
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.3)
                                              : Colors.black.withValues(alpha: 0.3),
                                        ),
                                      ),
                                    if (hop.city != null) ...[
                                      Text(
                                        ' • ',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.2)
                                              : Colors.black.withValues(alpha: 0.2),
                                        ),
                                      ),
                                      Icon(
                                        Icons.location_on_rounded,
                                        size: 11,
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.2)
                                            : Colors.black.withValues(alpha: 0.2),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${hop.city}, ${hop.countryCode ?? ""}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.3)
                                              : Colors.black.withValues(alpha: 0.3),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHopDetails(TracerouteHop hop, bool isDark) {
    if (hop.isTimeout) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.06),
            AppColors.accent.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          _detailRow('Hop', '${hop.hop}', isDark),
          _detailRow('IP Address', hop.ip ?? 'N/A', isDark),
          _detailRow('Hostname', hop.hostname ?? 'N/A', isDark),
          _detailRow(
            'Latency',
            hop.latency != null ? '${hop.latency!.toStringAsFixed(1)} ms' : 'N/A',
            isDark,
          ),
          _detailRow(
            'Location',
            hop.city != null
                ? '${hop.city}, ${hop.country ?? ""}'
                : 'Unknown',
            isDark,
          ),
          if (hop.latitude != null && hop.longitude != null)
            _detailRow(
              'Coordinates',
              '${hop.latitude!.toStringAsFixed(3)}, ${hop.longitude!.toStringAsFixed(3)}',
              isDark,
            ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TracerouteNodePainter extends CustomPainter {
  final List<TracerouteHop> hops;
  final bool isDark;
  final double animValue;
  final int? selectedHop;

  _TracerouteNodePainter({
    required this.hops,
    required this.isDark,
    required this.animValue,
    this.selectedHop,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (hops.length < 2) return;

    final paint = Paint()..style = PaintingStyle.fill;

    final nodeX = 64.0;
    for (int i = 0; i < hops.length - 1; i++) {
      final y1 = 12.0 + i * 88.0 + 44.0;
      final y2 = 12.0 + (i + 1) * 88.0 + 44.0;

      final hop = hops[i];
      final color = hop.latency != null
          ? AppColors.getLatencyColor(hop.latency!)
          : Colors.grey;

      final particleProgress = (animValue + i * 0.15) % 1.0;
      final particleY = y1 + (y2 - y1) * particleProgress;

      paint.color = color.withValues(alpha: 0.6 * (1 - particleProgress));
      canvas.drawCircle(
        Offset(nodeX, particleY),
        3 * (1 - particleProgress * 0.5),
        paint,
      );

      final p2 = (animValue + i * 0.15 + 0.5) % 1.0;
      final p2Y = y1 + (y2 - y1) * p2;
      paint.color = color.withValues(alpha: 0.4 * (1 - p2));
      canvas.drawCircle(
        Offset(nodeX, p2Y),
        2.5 * (1 - p2 * 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TracerouteNodePainter oldDelegate) {
    return oldDelegate.animValue != animValue ||
        oldDelegate.selectedHop != selectedHop;
  }
}
