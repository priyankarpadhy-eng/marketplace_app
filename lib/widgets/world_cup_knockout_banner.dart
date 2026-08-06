import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:market_app/models/world_cup_match.dart';
import 'package:market_app/services/world_cup_service.dart';
import 'package:market_app/theme/app_theme.dart';
import 'package:shimmer/shimmer.dart';

class WorldCupKnockoutBanner extends StatefulWidget {
  const WorldCupKnockoutBanner({super.key});

  @override
  State<WorldCupKnockoutBanner> createState() => _WorldCupKnockoutBannerState();
}

class _WorldCupKnockoutBannerState extends State<WorldCupKnockoutBanner> {
  List<WorldCupMatch> _matches = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Auto-refresh every 60 seconds to keep scores updated
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) => _loadData(silent: true));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
      if (mounted) setState(() => _isLoading = true);
    }
    final fetched = await WorldCupService.instance.fetchKnockoutMatches();
    if (mounted) {
      setState(() {
        _matches = fetched;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return _buildShimmer(isDark);
    }

    if (_matches.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort matches so live ones appear first, then upcoming, then finished
    final sortedMatches = List<WorldCupMatch>.from(_matches)..sort((a, b) {
      if (a.timeElapsed.toLowerCase() == 'live' && b.timeElapsed.toLowerCase() != 'live') return -1;
      if (a.timeElapsed.toLowerCase() != 'live' && b.timeElapsed.toLowerCase() == 'live') return 1;
      if (!a.finished && b.finished) return -1;
      if (a.finished && !b.finished) return 1;
      return int.parse(a.id).compareTo(int.parse(b.id));
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Widget Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FIFA WORLD CUP 2026',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.accent(isDark),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Knockout Stages',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary(isDark),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _showBracketSheet(context, _matches),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accent(isDark).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.accent(isDark).withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_tree_rounded,
                        size: 13,
                        color: AppTheme.accent(isDark),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Bracket',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accent(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Horizontal Matches List
        SizedBox(
          height: 146,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sortedMatches.length,
            itemBuilder: (context, index) {
              final match = sortedMatches[index];
              return _buildMatchCard(context, match, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMatchCard(BuildContext context, WorldCupMatch match, bool isDark) {
    final isLive = match.timeElapsed.toLowerCase() == 'live';
    final isUpcoming = !match.finished && !isLive;
    
    return Container(
      width: 250,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLive 
              ? AppTheme.accent(isDark).withOpacity(0.6) 
              : AppTheme.border(isDark),
          width: isLive ? 1.5 : 1.0,
        ),
        boxShadow: isLive ? [
          BoxShadow(
            color: AppTheme.accent(isDark).withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ] : [],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showMatchDetails(context, match),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Header: Match stage & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Match ${match.id} · ${match.stageName.toUpperCase()}',
                    style: GoogleFonts.roboto(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary(isDark),
                      letterSpacing: 0.5,
                    ),
                  ),
                  _buildStatusPill(match, isDark),
                ],
              ),
              const Spacer(),
              
              // Team Row 1: Home
              _buildTeamRow(match.homeDisplayName, match.homeScore, isUpcoming, isDark),
              const SizedBox(height: 6),
              
              // Team Row 2: Away
              _buildTeamRow(match.awayDisplayName, match.awayScore, isUpcoming, isDark),
              const Spacer(),
              
              // Match footer date/time info
              Text(
                match.localDate,
                style: GoogleFonts.roboto(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamRow(String teamName, int score, bool isUpcoming, bool isDark) {
    final nameLimit = teamName.length > 20 ? '${teamName.substring(0, 18)}...' : teamName;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 24,
                height: 16,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  teamName.length >= 3 ? teamName.substring(0, 3).toUpperCase() : teamName.toUpperCase(),
                  style: GoogleFonts.roboto(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textSecondary(isDark),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nameLimit,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary(isDark),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (!isUpcoming)
          Text(
            score.toString(),
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary(isDark),
            ),
          )
        else
          Text(
            '-',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary(isDark),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusPill(WorldCupMatch match, bool isDark) {
    final elapsed = match.timeElapsed.toLowerCase();
    
    if (match.finished) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.black12,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'FT',
          style: GoogleFonts.roboto(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: AppTheme.textSecondary(isDark),
          ),
        ),
      );
    }

    if (elapsed == 'live') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'LIVE',
              style: GoogleFonts.roboto(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: Colors.red,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.accent(isDark).withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'VS',
        style: GoogleFonts.roboto(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          color: AppTheme.accent(isDark),
        ),
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 140, height: 28, color: Colors.grey.withOpacity(0.2)),
              Container(width: 80, height: 24, color: Colors.grey.withOpacity(0.2)),
            ],
          ),
        ),
        SizedBox(
          height: 146,
          child: Shimmer.fromColors(
            baseColor: isDark ? const Color(0xFF1E293B) : Colors.grey[300]!,
            highlightColor: isDark ? const Color(0xFF334155) : Colors.grey[100]!,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 3,
              itemBuilder: (context, index) => Container(
                width: 250,
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showMatchDetails(BuildContext context, WorldCupMatch match) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Match ${match.id} Details',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary(isDark),
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailedRow(match.homeDisplayName, match.homeScore, match.homeScorers, isDark),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Colors.white10),
              ),
              _buildDetailedRow(match.awayDisplayName, match.awayScore, match.awayScorers, isDark),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent(isDark),
                    foregroundColor: isDark ? AppTheme.darkBg : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailedRow(String teamName, int score, String scorers, bool isDark) {
    final displayScorers = scorers == 'null' || scorers.isEmpty ? 'No goals recorded' : scorers;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                teamName,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary(isDark),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayScorers,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: AppTheme.textSecondary(isDark),
                ),
              ),
            ],
          ),
        ),
        Text(
          score.toString(),
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary(isDark),
          ),
        ),
      ],
    );
  }

  void _showBracketSheet(BuildContext context, List<WorldCupMatch> matches) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            // Group matches by type
            final r32 = matches.where((m) => m.type.toLowerCase() == 'r32').toList();
            final r16 = matches.where((m) => m.type.toLowerCase() == 'r16').toList();
            final qf = matches.where((m) => m.type.toLowerCase() == 'qf').toList();
            final sf = matches.where((m) => m.type.toLowerCase() == 'sf').toList();
            final finals = matches.where((m) => m.type.toLowerCase() == 'final' || m.type.toLowerCase() == 'third').toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tournament Bracket',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary(isDark),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.white10),
                Expanded(
                  child: DefaultTabController(
                    length: 5,
                    child: Column(
                      children: [
                        TabBar(
                          isScrollable: true,
                          indicatorColor: AppTheme.accent(isDark),
                          labelColor: AppTheme.textPrimary(isDark),
                          unselectedLabelColor: AppTheme.textSecondary(isDark),
                          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
                          tabs: const [
                            Tab(text: 'R32'),
                            Tab(text: 'R16'),
                            Tab(text: 'QF'),
                            Tab(text: 'SF'),
                            Tab(text: 'Finals'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _buildBracketStageList(r32, isDark, scrollController),
                              _buildBracketStageList(r16, isDark, scrollController),
                              _buildBracketStageList(qf, isDark, scrollController),
                              _buildBracketStageList(sf, isDark, scrollController),
                              _buildBracketStageList(finals, isDark, scrollController),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBracketStageList(List<WorldCupMatch> stageMatches, bool isDark, ScrollController controller) {
    if (stageMatches.isEmpty) {
      return Center(
        child: Text(
          'No matches scheduled for this stage.',
          style: GoogleFonts.outfit(color: AppTheme.textSecondary(isDark)),
        ),
      );
    }

    return ListView.builder(
      controller: controller,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: stageMatches.length,
      itemBuilder: (context, index) {
        final match = stageMatches[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface(isDark),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border(isDark)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Match ${match.id} · ${match.localDate}',
                      style: GoogleFonts.roboto(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary(isDark),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          match.homeDisplayName,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary(isDark),
                          ),
                        ),
                        if (!match.finished && match.timeElapsed == 'notstarted')
                          Text('-', style: GoogleFonts.outfit(color: AppTheme.textSecondary(isDark)))
                        else
                          Text(
                            match.homeScore.toString(),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary(isDark),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          match.awayDisplayName,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary(isDark),
                          ),
                        ),
                        if (!match.finished && match.timeElapsed == 'notstarted')
                          Text('-', style: GoogleFonts.outfit(color: AppTheme.textSecondary(isDark)))
                        else
                          Text(
                            match.awayScore.toString(),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary(isDark),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildStatusPill(match, isDark),
            ],
          ),
        );
      },
    );
  }
}
