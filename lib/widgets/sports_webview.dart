import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:market_app/theme/app_theme.dart';

class SportsWebView extends StatefulWidget {
  final VoidCallback onClose;
  const SportsWebView({super.key, required this.onClose});

  @override
  State<SportsWebView> createState() => _SportsWebViewState();
}

class _SportsWebViewState extends State<SportsWebView> {
  WebViewController? _controller;
  bool _isLoading = true;
  int _refreshCount = 0;
  String _url = 'https://igitmarketplace.vercel.app/events'; // Default mobile sports/events portal

  Future<void> _handleRefresh() async {
    if (_refreshCount >= 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refresh limit reached to prevent spam.'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    
    if (_controller != null) {
      setState(() {
        _refreshCount++;
        _isLoading = true;
      });
      await _controller!.clearCache();
      await _controller!.reload();
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUrlAndInit();
  }

  Future<void> _fetchUrlAndInit() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('sports_config')
          .get()
          .timeout(const Duration(seconds: 4));
          
      if (doc.exists && doc.data() != null && doc.data()!.containsKey('url')) {
        final dbUrl = doc.data()!['url']?.toString();
        if (dbUrl != null && dbUrl.isNotEmpty) {
          _url = dbUrl;
        }
      }
    } catch (_) {
      // Fallback to default
    }

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            // Only allow the configured URL — block everything else
            if (request.url == _url || request.url.startsWith(_url)) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(_url));

    if (mounted) {
      setState(() {
        _controller = controller;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget body;
    if (_controller == null) {
      body = Center(
        child: CircularProgressIndicator(
          color: AppTheme.accent(isDark),
        ),
      );
    } else {
      body = Stack(
        children: [
          WebViewWidget(controller: _controller!),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                color: AppTheme.accent(isDark),
              ),
            ),
        ],
      );
    }

    return Container(
      color: AppTheme.surface(isDark),
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppTheme.surface(isDark),
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.accent(isDark).withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary(isDark)),
                    onPressed: widget.onClose,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sports',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary(isDark),
                      letterSpacing: -0.5,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.refresh_rounded, color: AppTheme.textPrimary(isDark)),
                    tooltip: 'Hard Refresh (${5 - _refreshCount} left)',
                    onPressed: _refreshCount >= 5 ? null : _handleRefresh,
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
