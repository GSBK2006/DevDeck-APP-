import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Import Intl
import 'theme.dart';
import 'data.dart';
import 'project_detail_page.dart';

class ProjectCard extends StatefulWidget {
  final Project project;
  const ProjectCard({super.key, required this.project});

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  bool _isBoosting = false;

  Future<void> _boost() async {
    if (_isBoosting) return;
    setState(() {
      _isBoosting = true;
      widget.project.votes++;
    });

    try {
      await Supabase.instance.client
          .from('projects')
          .update({'votes': widget.project.votes}).eq('id', widget.project.id);
    } catch (e) {
      setState(() => widget.project.votes--);
      debugPrint("Boost Error: $e");
    } finally {
      if (mounted) setState(() => _isBoosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color borderColor = isDark ? Colors.white12 : Colors.black12;
    Color glowColor = Colors.transparent;
    String tierText = "COMMON";

    if (widget.project.votes >= 50) {
      borderColor = AppTheme.neonGold;
      glowColor = AppTheme.neonGold.withOpacity(0.5);
      tierText = "MYTHIC // LEGENDARY";
    } else if (widget.project.votes >= 10) {
      borderColor = AppTheme.neonBlue;
      glowColor = AppTheme.neonBlue.withOpacity(0.4);
      tierText = "RARE // UNCOMMON";
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ProjectDetailPage(project: widget.project)));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: borderColor, width: widget.project.votes >= 50 ? 2 : 1),
          boxShadow: [
            BoxShadow(color: glowColor, blurRadius: 20, spreadRadius: 0)
          ],
        ),
        child: isDark
            ? _buildGlassCard(borderColor, tierText, theme)
            : _buildLightCard(borderColor, tierText, theme),
      ),
    );
  }

  Widget _buildGlassCard(Color borderColor, String tierText, ThemeData theme) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 380,
      borderRadius: 20,
      blur: 20,
      alignment: Alignment.center,
      border: 0,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFffffff).withOpacity(0.1),
          const Color(0xFFFFFFFF).withOpacity(0.05)
        ],
      ),
      borderGradient:
          LinearGradient(colors: [borderColor, borderColor.withOpacity(0.1)]),
      child: _buildCardContent(borderColor, tierText, theme, isDark: true),
    );
  }

  Widget _buildLightCard(Color borderColor, String tierText, ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 380,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: _buildCardContent(borderColor, tierText, theme, isDark: false),
    );
  }

  Widget _buildCardContent(Color borderColor, String tierText, ThemeData theme,
      {required bool isDark}) {
    // DATE FORMATTER
    final dateString =
        DateFormat('MMM d, y • h:mm a').format(widget.project.createdAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                image: DecorationImage(
                    image: NetworkImage(widget.project.imageUrl),
                    fit: BoxFit.cover),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: borderColor)),
                child: Text(tierText,
                    style: AppTheme.fontCode.copyWith(
                        color: borderColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.project.title,
                  style: theme.textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(PhosphorIcons.user(),
                      size: 14, color: theme.textTheme.bodyMedium?.color),
                  const SizedBox(width: 5),
                  Text("@${widget.project.author}",
                      style:
                          theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
                  const SizedBox(width: 10),
                  // TIMESTAMP DISPLAY
                  Text(dateString,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontSize: 10, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 8,
                children: widget.project.techStack
                    .map((tech) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey.shade100,
                            border: Border.all(
                                color: isDark
                                    ? Colors.white24
                                    : Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(tech.toUpperCase(),
                              style: AppTheme.fontCode.copyWith(
                                  fontSize: 10,
                                  color: theme.textTheme.bodyMedium?.color)),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            border: Border(
                top: BorderSide(
                    color: isDark ? Colors.white10 : Colors.black12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: _boost,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: widget.project.votes >= 10
                          ? borderColor.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      Icon(PhosphorIcons.rocketLaunch(PhosphorIconsStyle.fill),
                              color: widget.project.votes >= 10
                                  ? borderColor
                                  : Colors.grey,
                              size: 20)
                          .animate(target: widget.project.votes > 0 ? 1 : 0)
                          .shake(),
                      const SizedBox(width: 8),
                      Text("${widget.project.votes} BOOSTS",
                          style: AppTheme.fontCode.copyWith(
                              color: theme.textTheme.bodyLarge?.color,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              Icon(PhosphorIcons.shareNetwork(),
                  color: theme.iconTheme.color?.withOpacity(0.5), size: 20),
            ],
          ),
        )
      ],
    );
  }
}
