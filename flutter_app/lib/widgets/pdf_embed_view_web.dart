import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class PdfEmbedView extends StatelessWidget {
  const PdfEmbedView({
    super.key,
    required this.url,
    this.height = 640,
  });

  final String url;
  final double height;

  static final Set<String> _registeredViewTypes = <String>{};

  String get _viewType =>
      'pdf-embed-${base64Url.encode(utf8.encode(url)).replaceAll('=', '')}';

  void _registerIfNeeded() {
    if (_registeredViewTypes.contains(_viewType)) {
      return;
    }
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      return html.EmbedElement()
        ..src = '$url#toolbar=0&navpanes=0&scrollbar=0&view=FitH'
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.pointerEvents = 'none';
    });
    _registeredViewTypes.add(_viewType);
  }

  @override
  Widget build(BuildContext context) {
    _registerIfNeeded();
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
