class ErrorParser {
  static String getCleanErrorMessage(dynamic e) {
    final str = e.toString();
    final postgrestMatch = RegExp(
      r'PostgrestException\(message:\s*(.*?),\s*code:',
      caseSensitive: false,
    ).firstMatch(str);

    if (postgrestMatch != null) {
      return postgrestMatch.group(1)?.trim() ?? str;
    }
    var clean = str;
    if (clean.startsWith('Exception:')) {
      clean = clean.substring('Exception:'.length).trim();
    }
    if (clean.startsWith('Error al enviar el mensaje:')) {
      clean = clean.substring('Error al enviar el mensaje:'.length).trim();
    }
    if (clean.startsWith('Exception:')) {
      clean = clean.substring('Exception:'.length).trim();
    }
    return clean;
  }
}
