import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class VRMViewer extends StatefulWidget {
  final String? vrmUrl;
  final String? animationUrl;
  final double height;
  final bool visible;

  const VRMViewer({
    super.key,
    this.vrmUrl,
    this.animationUrl,
    this.height = 400,
    this.visible = true,
  });

  @override
  State<VRMViewer> createState() => _VRMViewerState();
}

class _VRMViewerState extends State<VRMViewer> {
  InAppWebViewController? _webViewController;
  bool _loaded = false;

  @override
  void didUpdateWidget(VRMViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vrmUrl != widget.vrmUrl && widget.vrmUrl != null) {
      _loadVRM(widget.vrmUrl!);
    }
    if (oldWidget.animationUrl != widget.animationUrl && widget.animationUrl != null) {
      _loadAnimation(widget.animationUrl!);
    }
  }

  void _loadVRM(String url) {
    _webViewController?.evaluateJavascript(
      source: "window.VRMBridge.loadVRM('$url');",
    );
  }

  void _loadAnimation(String url) {
    _webViewController?.evaluateJavascript(
      source: "window.VRMBridge.loadAnimation('$url');",
    );
  }

  void setExpression(String expression) {
    _webViewController?.evaluateJavascript(
      source: "window.VRMBridge.setExpression('$expression');",
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          InAppWebView(
            initialFile: 'assets/html/vrm_viewer.html',
            initialSettings: InAppWebViewSettings(
              transparentBackground: true,
              disableVerticalScroll: true,
              disableHorizontalScroll: true,
              supportZoom: false,
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
              isInspectable: false,
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
              controller.addJavaScriptHandler(
                handlerName: 'FlutterChannel',
                callback: (args) {
                  // Handle messages from JS
                },
              );
            },
            onLoadStop: (controller, url) {
              setState(() => _loaded = true);
              if (widget.vrmUrl != null) {
                _loadVRM(widget.vrmUrl!);
              }
              if (widget.animationUrl != null) {
                _loadAnimation(widget.animationUrl!);
              }
            },
          ),
          if (!_loaded)
            Container(
              color: Colors.transparent,
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF7C3AED),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
