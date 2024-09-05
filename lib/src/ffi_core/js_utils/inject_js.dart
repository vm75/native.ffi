import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;

/// Injects the library by its [url].
/// Throws an [UnsupportedError] if the [dart:html] library is not present.
///
/// This works by adding a new script tag to the html page with the src tag set to url.
Future<void> importLibrary(String url) {
  return _importJsLibraries([url]);
}

/// Injects the javascript code [src] into the page.
/// Throws an [UnsupportedError] if the [dart:html] library is not present.
///
/// This works by adding a new script tag to the html page with innerText set to src.
Future<void> injectScript(String src) {
  return _injectJsSource([src]);
}

/// Checks if a library is present in the page.
/// Throws an [UnsupportedError] if the [dart:html] library is not present.
///
/// This happens by checking the src field of all script tags in the html page.
bool isImported(String url) {
  return _isLoaded(_htmlHead(), url);
}

web.HTMLScriptElement _createScriptTagFromUrl(String library) =>
    web.HTMLScriptElement()
      ..type = 'text/javascript'
      ..charset = 'utf-8'
      ..async = true
      //..defer = true
      ..src = library;

web.HTMLScriptElement _createScriptTagFromSrc(String src) =>
    web.HTMLScriptElement()
      ..type = 'text/javascript'
      ..charset = 'utf-8'
      ..async = false
      //..defer = true
      ..innerText = src;

Future<void> _importJsLibraries(List<String> libraries) {
  List<Future<void>> loading = <Future<void>>[];
  web.Element head = _htmlHead();
  for (String library in libraries) {
    if (!isImported(library)) {
      final scriptTag = _createScriptTagFromUrl(library);
      head.appendChild(scriptTag);
      loading.add(scriptTag.onLoad.first);
    }
  }
  return Future.wait(loading);
}

Future<void> _injectJsSource(List<String> src) {
  List<Future<void>> loading = <Future<void>>[];
  web.Element head = _htmlHead();
  for (String script in src) {
    final scriptTag = _createScriptTagFromSrc(script);
    head.appendChild(scriptTag);
    loading.add(scriptTag.onLoad.first);
  }
  return Future.wait(loading);
}

web.Element _htmlHead() {
  web.Element? head = web.document.querySelector('head');
  if (head != null) {
    return head;
  } else {
    throw StateError('Could not fetch html head element!');
  }
}

bool _isLoaded(web.Element head, String url) {
  if (url.startsWith('./')) {
    url = url.replaceFirst('./', '');
  }
  for (int i = 0; i < head.children.length; i++) {
    web.Element? element = head.children.item(i);
    if (element != null) {
      final src = element.getProperty('src'.toJS);
      if (src is JSString && src.toDart.endsWith(url)) {
        return true;
      }
    }
  }
  return false;
}