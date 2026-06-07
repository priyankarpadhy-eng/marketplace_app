import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final int maxLines;
  final Color? linkColor;

  const ExpandableText({
    super.key,
    required this.text,
    required this.style,
    this.maxLines = 3,
    this.linkColor,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _isExpanded = false;

  List<TextSpan> _linkify(String text) {
    final List<TextSpan> spans = [];
    final RegExp linkRegExp = RegExp(
      r'(https?:\/\/[^\s]+)',
      caseSensitive: false,
    );

    int start = 0;
    for (final Match match in linkRegExp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }

      final String url = match.group(0)!;
      spans.add(
        TextSpan(
          text: url,
          style: TextStyle(
            color: widget.linkColor ?? const Color(0xFF6A5AE0),
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.bold,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final Uri uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
        ),
      );
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(text: widget.text, style: widget.style);
        final textPainter = TextPainter(
          text: textSpan,
          maxLines: widget.maxLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflowing = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: _linkify(widget.text),
                style: widget.style,
              ),
              maxLines: _isExpanded ? null : widget.maxLines,
              overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (isOverflowing)
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    _isExpanded ? "Show Less" : "View More",
                    style: GoogleFonts.outfit(
                      color: widget.linkColor ?? const Color(0xFF6A5AE0),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

