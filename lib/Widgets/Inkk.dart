// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart' as link;

class Inkk extends StatelessWidget {
  final Widget child;
  final Color? spalshColor;
  final Color? hoverColor;
  final double radius;
  final String? tooltip;
  final VoidCallback? onTap;
  final Function? onHovered;
  final VoidCallback? onDoubleTap;

  ///Link to be opened in new tab and same tab if [onTap] is not provided
  final String? url;

  ///To allow gesture input
  final bool allowGesture;
  final EdgeInsets? padding;

  ///Constructor
  const Inkk({
    super.key,
    required this.child,
    this.onTap,
    this.onHovered,
    this.radius = 8,
    this.spalshColor,
    this.tooltip,
    this.onDoubleTap,
    this.url,
    this.hoverColor,
    this.allowGesture = false,
    this.padding,
  });

  @override
  Widget build(final BuildContext context) {
    final Widget parent = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: _z,
        child: _stack(),
      ),
    );

    if (url != null) {
      return _linker(parent);
    } else {
      final String? message = tooltip != null && tooltip!.isNotEmpty ? tooltip : null;
      return message == null ? parent : Tooltip(message: message, child: parent);
    }
  }

  Widget _linker(final Widget c) {
    return link.Link(
      uri: Uri.parse(url!),
      target: link.LinkTarget.blank,
      builder: (final BuildContext context, final link.FollowLink? followLink) {
        return c;
      },
    );
  }

  Widget _stack() {
    return Stack(
      children: <Widget>[
        if (allowGesture) GestureDetector(onTap: onTap, child: child) else child,
        if (allowGesture == false)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              borderRadius: _z,
              child: InkWell(
                hoverColor: hoverColor ?? Colors.transparent,
                highlightColor: (spalshColor ?? Colors.blue).withValues(alpha: 0.35),
                splashColor: (spalshColor ?? Colors.blue).withValues(alpha: 0.25),
                onTap: onTap ?? () {},
                onDoubleTap: onDoubleTap ?? () {},
                onHover: (final _) {
                  if (onHovered != null) {
                    onHovered!();
                  }
                },
              ),
            ),
          ),
      ],
    );
  }

  BorderRadius get _z => BorderRadius.circular(radius);
}
