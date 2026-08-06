import 'package:flutter/material.dart';



/// Customized text widget with various styling options.
class Txt extends StatefulWidget {
  /// The text to be displayed.
  final dynamic text;

  /// FontStyle of the text.
  final FontStyle? style;

  /// FontWeight of the text.
  final FontWeight? fontWeight;

  /// Maximum number of lines for text.
  final int? maxlines;

  /// Font size of the text.
  final double? fontSize;

  /// Text color.
  final Color? color;

  /// Text alignment.
  final TextAlign? textAlign;
  final TextStyle? textStyle;

  /// Whether to apply text overflow ellipsis.
  final bool useoverflow;

  /// Whether to capitalize the first letter of the text.
  final bool upperCaseFirst;

  /// Whether to enclose the text in quotes.
  final bool quoted;

  /// Whether to underline the text.
  final bool underline;

  /// Whether to convert the text to full uppercase.
  final bool fullUpperCase;

  /// Font fontFamily for the text.
  final String? fontFamily;

  /// Whether to prepend an Indian Rupee symbol (₹) before the text.
  final bool toRupees;

  /// Whether to convert an integer value to a readable time format.
  final bool toTimeAgo;

  /// Prefix to be added before the text.
  final String? prefix;

  ///Suffix to be added after the text.
  final String? suffix;

  /// Whether to apply a strike-through effect to the text.
  final bool strikeThrough;

  ///If the string can be selected by clicking on it
  final bool? selectable;

  ///Space between each letters of a word
  final double? letterSpacing;

  ///Space between each lines
  final double? lineSpacing;

  /// Constructor for the Txt widget.
  const Txt(
    this.text, {
    super.key,
    this.style,
    this.fontWeight,
    this.maxlines,
    this.fontSize,
    this.color,
    this.textAlign,
    this.textStyle,
    this.useoverflow = false,
    this.upperCaseFirst = false,
    this.quoted = false,
    this.underline = false,
    this.fullUpperCase = false,
    this.selectable,
    this.fontFamily,
    this.prefix,
    this.suffix,
    this.toRupees = false,
    this.toTimeAgo = false,
    this.strikeThrough = false,
    this.letterSpacing,
    this.lineSpacing,
  });

  static String defaultFontFamily = 'Roboto';

  @override
  _TxtState createState() => _TxtState();
}

class _TxtState extends State<Txt> {
  String get fontFamily =>  Txt.defaultFontFamily;
  String finalText = '';

  static bool fontsLoaded = false;

  bool get isDouble => widget.text is double;
  bool get isInt => widget.text is int;

  @override
  void initState() {
    getFonts();
    super.initState();
  }

  Future<void> getFonts() async {
    if (fontsLoaded == false) {
      // await gfontlib.loadLibrary();
      // await gfontlib.loadLibrary();
      // await gfontlib.loadLibrary();
      if (mounted) {
        setState(() => fontsLoaded = true);
      }
    }
  }

  @override
  Widget build(final BuildContext context) {
    // Determine the final text based on widget configuration.
    if (widget.text is String) {
      finalText = widget.text?.toString() ?? 'Error';
    } else if (widget.text is num) {
      if (widget.toTimeAgo && widget.text is int) {
        finalText = (widget.text);
      } else {
        finalText = widget.text.toString();
      }
    } else {
      finalText = widget.text.toString();
    }


    // Apply text transformations.
    if (widget.upperCaseFirst) {
      finalText = finalText;
    }

    if (widget.fullUpperCase) {
      finalText = finalText.toUpperCase();
    }
    if (widget.quoted) {
      finalText = '❝$finalText❞';
    }

    if (widget.prefix != null && widget.toTimeAgo == false) {
      finalText = '${widget.prefix}$finalText';
    }

    if (widget.suffix != null) {
      finalText = '$finalText${widget.suffix}';
    }

    double? fontSize = widget.fontSize;
    final bool hasEnglishCharacters = RegExp('[a-zA-Z]').hasMatch(finalText);
    if (hasEnglishCharacters == false) {
      ///If no fontSize given, then set it to default as [14]
      fontSize = widget.fontSize ?? 14;

      ///And then reduce [2] pixels from the given fontSize
      fontSize = fontSize - 2;
    }

    ///Mac doesnt show bold fonts, so we need to see it!
    final TextStyle _style = widget.textStyle ??
        // kDebugMode && kIsWeb == false

        (TextStyle(
                height: widget.lineSpacing,
                letterSpacing: widget.letterSpacing,
                decoration: widget.underline
                    ? TextDecoration.underline
                    : (widget.strikeThrough ? TextDecoration.lineThrough : null),
                color: widget.color,
                fontSize: fontSize,
                fontWeight: widget.fontWeight,
                fontStyle: widget.style,
              )
              );
    final bool _tsel = widget.selectable ?? false;

    if (_tsel) {
      return SelectableText(
        finalText,
        textAlign: widget.textAlign,
        maxLines: widget.maxlines,
        textScaler: TextScaler.noScaling,
        style: _style,
      );
    } else {
      return Text(
        finalText,
        overflow: widget.useoverflow ? TextOverflow.ellipsis : null,
        textAlign: widget.textAlign,
        maxLines: widget.maxlines,
        textScaler: TextScaler.noScaling,
        style: _style,
      );
    }
  }
}
