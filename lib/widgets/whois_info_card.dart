import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:netscope/models/website_info.dart';
import 'package:netscope/providers/theme_provider.dart';
import 'package:netscope/theme/app_theme.dart';

class WhoisInfoCard extends StatefulWidget {
  final WhoisInfo info;

  const WhoisInfoCard({super.key, required this.info});

  @override
  State<WhoisInfoCard> createState() => _WhoisInfoCardState();
}

class _WhoisInfoCardState extends State<WhoisInfoCard> {
  bool _expanded = false;

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
                  child: const Icon(Icons.shield_rounded,
                      color: AppColors.accentSecondary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'WHOIS INFORMATION',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.accentSecondary,
                    ),
                  ),
                ),
                IconButton(
                  icon: AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.expand_more_rounded, size: 24),
                  ),
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildRow('Registrar', widget.info.registrar, isDark),
                _buildDivider(isDark),
                _buildRow('Created', widget.info.creationDate, isDark,
                    icon: Icons.calendar_today_rounded),
                _buildDivider(isDark),
                _buildRow('Expires', widget.info.expirationDate, isDark,
                    icon: Icons.event_rounded,
                    valueColor: _isExpiringSoon()
                        ? AppColors.warning
                        : null),
                _buildDivider(isDark),
                _buildRow('Updated', widget.info.updatedDate, isDark,
                    icon: Icons.update_rounded),
                if (_expanded) ...[
                  _buildDivider(isDark),
                  _buildRow('Name Servers', widget.info.nameServers, isDark,
                      icon: Icons.dns_rounded),
                  _buildDivider(isDark),
                  _buildRow('Status', widget.info.status, isDark,
                      icon: Icons.verified_rounded),
                  _buildDivider(isDark),
                  _buildRow(
                      'Organization', widget.info.registrantOrg, isDark,
                      icon: Icons.business_rounded),
                  _buildDivider(isDark),
                  _buildRow('Country', widget.info.registrantCountry, isDark,
                      icon: Icons.flag_rounded),
                ],
              ],
            ),
          ),

          if (!_expanded)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _expanded = true),
                  icon: const Icon(Icons.expand_more_rounded, size: 18),
                  label: Text(
                    'Show More',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isExpiringSoon() {
    if (widget.info.expirationDate == null) return false;
    try {
      final expDate = DateTime.parse(widget.info.expirationDate!);
      return expDate.difference(DateTime.now()).inDays < 90;
    } catch (_) {
      return false;
    }
  }

  Widget _buildRow(String label, String? value, bool isDark,
      {IconData? icon, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon,
                size: 16,
                color: isDark ? Colors.white24 : Colors.black26),
            const SizedBox(width: 10),
          ],
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
              value ?? 'N/A',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
              textAlign: TextAlign.right,
              maxLines: 3,
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
