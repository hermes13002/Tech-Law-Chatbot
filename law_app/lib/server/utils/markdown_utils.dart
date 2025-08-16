/// Utility class for handling markdown and HTML text processing
class MarkdownUtils {
  static final MarkdownUtils _instance = MarkdownUtils._internal();
  
  // Regular expressions for markdown and HTML elements
  final RegExp htmlTags = RegExp(r'<[^>]+>');
  final RegExp boldMarkdown = RegExp(r'\*\*(.*?)\*\*');
  final RegExp italicMarkdown = RegExp(r'\*(.*?)\*');
  final RegExp codeMarkdown = RegExp(r'`(.*?)`');
  final RegExp headersMarkdown = RegExp(r'#+ ');
  final RegExp listMarkers = RegExp(r'\n\s*[\*\-\+]\s+');
  final RegExp numberedLists = RegExp(r'\n\s*\d+\.\s+');
  
  // Singleton pattern
  factory MarkdownUtils() {
    return _instance;
  }
  
  MarkdownUtils._internal();
  
  /// Strip markdown and HTML formatting from text
  /// 
  /// This is used to clean AI responses from formatting that might not be
  /// properly handled by the client
  String stripMarkdownAndHtml(String text) {
    return text
      .replaceAll(htmlTags, '')
      .replaceAllMapped(boldMarkdown, (match) => match.group(1) ?? '')
      .replaceAllMapped(italicMarkdown, (match) => match.group(1) ?? '')
      .replaceAllMapped(codeMarkdown, (match) => match.group(1) ?? '')
      .replaceAll(headersMarkdown, '')
      .replaceAll(listMarkers, '\n- ')
      .replaceAll(numberedLists, '\n1. ')
      .trim();
  }
  
  /// Convert plain text to simple HTML
  /// 
  /// This can be used if we need to convert plain text to HTML for display
  String textToHtml(String text) {
    return text
      .replaceAll('\n', '<br>')
      .replaceAll('  ', '&nbsp;&nbsp;');
  }
}