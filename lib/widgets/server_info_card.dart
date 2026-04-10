import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:netscope/models/website_info.dart';
import 'package:netscope/providers/theme_provider.dart';
import 'package:netscope/theme/app_theme.dart';

class ServerInfoCard extends StatelessWidget {
  final ServerInfo info;

  const ServerInfoCard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

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
                  AppColors.accent.withValues(alpha: 0.08),
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
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.dns_rounded,
                      color: AppColors.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'SERVER INFORMATION',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),

          // Info rows
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                  'IP Address',
                  info.ip ?? 'N/A',
                  Icons.router_rounded,
                  isDark,
                ),
                _buildDivider(isDark),
                _buildInfoRow(
                  'Server Type',
                  info.serverType ?? 'N/A',
                  Icons.storage_rounded,
                  isDark,
                ),
                _buildDivider(isDark),
                _buildInfoRow(
                  'Hosting',
                  info.hostingProvider ?? 'N/A',
                  Icons.cloud_rounded,
                  isDark,
                ),
                _buildDivider(isDark),
                _buildInfoRow(
                  'ISP',
                  info.isp ?? 'N/A',
                  Icons.business_rounded,
                  isDark,
                ),
                _buildDivider(isDark),
                _buildInfoRow(
                  'Location',
                  '${info.city ?? "Unknown"}, ${info.country ?? "Unknown"}',
                  Icons.location_on_rounded,
                  isDark,
                  valueColor: AppColors.accentSecondary,
                ),
                _buildDivider(isDark),
                _buildInfoRow(
                  'Organization',
                  info.org ?? 'N/A',
                  Icons.corporate_fare_rounded,
                  isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon,
    bool isDark, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: isDark ? Colors.white24 : Colors.black26),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white38 : Colors.black45,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark
          ? AppColors.darkBorder.withValues(alpha: 0.4)
          : AppColors.lightBorder.withValues(alpha: 0.6),
    );
  }
}
