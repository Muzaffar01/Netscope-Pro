import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:netscope/models/website_info.dart';
import 'package:netscope/providers/theme_provider.dart';
import 'package:netscope/theme/app_theme.dart';

class TracerouteMap extends StatefulWidget {
  final TracerouteResult traceroute;

  const TracerouteMap({super.key, required this.traceroute});

  @override
  State<TracerouteMap> createState() => _TracerouteMapState();
}

class _TracerouteMapState extends State<TracerouteMap> {
  final MapController _mapController = MapController();
  int? _selectedMarker;

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final geoHops = widget.traceroute.hops
        .where((h) =>
            h.latitude != null &&
            h.longitude != null &&
            !h.isTimeout &&
            h.latitude != 0.0)
        .toList();

    if (geoHops.isEmpty) {
      print("[DEBUG] geoHops is empty! Total hops: ${widget.traceroute.hops.length}");
      for(var h in widget.traceroute.hops) {
        print("  Hop ${h.hop} IP: ${h.ip} Lat: ${h.latitude} Lng: ${h.longitude}");
      }
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
          child: Text(
            'No geolocation data available',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ),
      );
    }

    // Calculate bounds
    final points = geoHops
        .map((h) => LatLng(h.latitude!, h.longitude!))
        .toList();

    return Container(
      height: 380,
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
                  AppColors.accentSecondary.withValues(alpha: 0.08),
                  AppColors.primary.withValues(alpha: 0.04),
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
                    color: AppColors.accentSecondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.map_rounded,
                      color: AppColors.accentSecondary, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SERVER LOCATIONS',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.accentSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${geoHops.length} locations mapped',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Map
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16)),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: points.length == 1
                      ? points[0]
                      : LatLng(
                          points.map((p) => p.latitude).reduce((a, b) => a + b) /
                              points.length,
                          points.map((p) => p.longitude).reduce((a, b) => a + b) /
                              points.length,
                        ),
                  initialZoom: points.length == 1 ? 5 : 2,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                    maxZoom: 18,
                    userAgentPackageName: 'com.netscope.app',
                  ),

                  // Route polyline
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: points,
                        strokeWidth: 2.5,
                        color: AppColors.primary.withValues(alpha: 0.6),
                      ),
                    ],
                  ),

                  // Markers
                  MarkerLayer(
                    markers: List.generate(geoHops.length, (index) {
                      final hop = geoHops[index];
                      final latencyColor = hop.latency != null
                          ? AppColors.getLatencyColor(hop.latency!)
                          : AppColors.primary;
                      final isFirst = index == 0;
                      final isLast = index == geoHops.length - 1;
                      final isSelected = _selectedMarker == index;

                      return Marker(
                        point: LatLng(hop.latitude!, hop.longitude!),
                        width: isSelected ? 160 : 36,
                        height: isSelected ? 80 : 36,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMarker =
                                  _selectedMarker == index ? null : index;
                            });
                          },
                          child: isSelected
                              ? _buildExpandedMarker(hop, latencyColor, isDark)
                              : _buildMarker(
                                  hop, latencyColor, isFirst, isLast),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarker(
    TracerouteHop hop,
    Color color,
    bool isFirst,
    bool isLast,
  ) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: isFirst
            ? const Icon(Icons.my_location_rounded, size: 16, color: Colors.white)
            : isLast
                ? const Icon(Icons.flag_rounded, size: 16, color: Colors.white)
                : Text(
                    '${hop.hop}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
      ),
    );
  }

  Widget _buildExpandedMarker(
    TracerouteHop hop,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Hop ${hop.hop}: ${hop.city ?? "Unknown"}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (hop.latency != null)
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Text(
                '${hop.latency!.toStringAsFixed(1)}ms • ${hop.ip ?? ""}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
