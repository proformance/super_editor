import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';
import 'package:super_editor_markdown/super_editor_markdown.dart';
import 'package:text_table/text_table.dart';

import 'test_documents.dart';

/// Extensions on [WidgetTester] that configure and pump [SuperEditor]
/// document editors.
extension DocumentTester on WidgetTester {
  /// Starts the process for configuring and pumping a new [SuperEditor].
  ///
  /// Use the returned [TestDocumentSelector] to continue configuring the
  /// [SuperEditor].
  TestDocumentSelector createDocument() {
    return TestDocumentSelector(this);
  }

  /// Pumps a new [SuperEditor] using the existing [context].
  ///
  /// Use this method to simulate a [SuperEditor] whose widget tree changes.
  TestDocumentConfigurator updateDocument(TestDocumentContext context) {
    return TestDocumentConfigurator._fromExistingContext(this, context);
  }
}

/// Selects a [Document] configuration when composing a [SuperEditor]
/// widget in a test.
///
/// Each document selection returns a [TestDocumentConfigurator], which
/// is used to complete the configuration, and to pump the [SuperEditor].
class TestDocumentSelector {
  const TestDocumentSelector(this._widgetTester);

  final WidgetTester _widgetTester;

  TestDocumentConfigurator withCustomContent(MutableDocument document) {
    return TestDocumentConfigurator._(_widgetTester, document);
  }

  /// Configures the editor with a [Document] that's parsed from the
  /// given [markdown].
  TestDocumentConfigurator fromMarkdown(String markdown) {
    return TestDocumentConfigurator._(
      _widgetTester,
      deserializeMarkdownToDocument(markdown),
    );
  }

  TestDocumentConfigurator withSingleEmptyParagraph() {
    return TestDocumentConfigurator._(
      _widgetTester,
      singleParagraphEmptyDoc(),
    );
  }

  TestDocumentConfigurator withSingleParagraph() {
    return TestDocumentConfigurator._(
      _widgetTester,
      singleParagraphDoc(),
    );
  }

  TestDocumentConfigurator withTwoEmptyParagraphs() {
    return TestDocumentConfigurator._(
      _widgetTester,
      twoParagraphEmptyDoc(),
    );
  }

  TestDocumentConfigurator withLongTextContent() {
    return TestDocumentConfigurator._(
      _widgetTester,
      longTextDoc(),
    );
  }
}

/// Builder that configures and pumps a [SuperEditor] widget.
class TestDocumentConfigurator {
  TestDocumentConfigurator._fromExistingContext(this._widgetTester, this._existingContext) : _document = null;

  TestDocumentConfigurator._(this._widgetTester, this._document) : _existingContext = null;

  final WidgetTester _widgetTester;
  final MutableDocument? _document;
  final TestDocumentContext? _existingContext;
  DocumentGestureMode? _gestureMode;
  DocumentInputSource? _inputSource;
  ThemeData? _appTheme;
  Stylesheet? _stylesheet;
  final _addedComponents = <ComponentBuilder>[];
  bool _autoFocus = false;
  ui.Size? _editorSize;
  List<ComponentBuilder>? _componentBuilders;
  WidgetTreeBuilder? _widgetTreeBuilder;
  ScrollController? _scrollController;
  FocusNode? _focusNode;
  DocumentSelection? _selection;
  WidgetBuilder? _androidToolbarBuilder;
  WidgetBuilder? _iOSToolbarBuilder;

  /// Configures the [SuperEditor] for standard desktop interactions,
  /// e.g., mouse and keyboard input.
  TestDocumentConfigurator forDesktop({
    DocumentInputSource inputSource = DocumentInputSource.keyboard,
  }) {
    _inputSource = inputSource;
    _gestureMode = DocumentGestureMode.mouse;
    return this;
  }

  /// Configures the [SuperEditor] for standard Android interactions,
  /// e.g., touch gestures and IME input.
  TestDocumentConfigurator forAndroid() {
    _gestureMode = DocumentGestureMode.android;
    _inputSource = DocumentInputSource.ime;
    return this;
  }

  /// Configures the [SuperEditor] for standard iOS interactions,
  /// e.g., touch gestures and IME input.
  TestDocumentConfigurator forIOS() {
    _gestureMode = DocumentGestureMode.iOS;
    _inputSource = DocumentInputSource.ime;
    return this;
  }

  /// Configures the [SuperEditor] to use the given [inputSource].
  TestDocumentConfigurator withInputSource(DocumentInputSource inputSource) {
    _inputSource = inputSource;
    return this;
  }

  /// Configures the [SuperEditor] to use the given [gestureMode].
  TestDocumentConfigurator withGestureMode(DocumentGestureMode gestureMode) {
    _gestureMode = gestureMode;
    return this;
  }

  /// Configures the [SuperEditor] to constrain its maxHeight and maxWidth using the given [size].
  TestDocumentConfigurator withEditorSize(ui.Size? size) {
    _editorSize = size;
    return this;
  }

  /// Configures the [SuperEditor] to use only the given [componentBuilders]
  TestDocumentConfigurator withComponentBuilders(List<ComponentBuilder>? componentBuilders) {
    _componentBuilders = componentBuilders;
    return this;
  }

  /// Configures the [SuperEditor] to use a custom widget tree above [SuperEditor].
  TestDocumentConfigurator withCustomWidgetTreeBuilder(WidgetTreeBuilder? builder) {
    _widgetTreeBuilder = builder;
    return this;
  }

  /// Configures the [SuperEditor] to use the given [scrollController]
  TestDocumentConfigurator withScrollController(ScrollController? scrollController) {
    _scrollController = scrollController;
    return this;
  }

  /// Configures the [SuperEditor] to use the given [focusNode]
  TestDocumentConfigurator withFocusNode(FocusNode? focusNode) {
    _focusNode = focusNode;
    return this;
  }

  /// Configures the [SuperEditor] to use the given [selection] as its initial selection.
  TestDocumentConfigurator withSelection(DocumentSelection? selection) {
    _selection = selection;
    return this;
  }

  /// Configures the [SuperEditor] to use the given [builder] as its android toolbar builder.
  TestDocumentConfigurator withAndroidToolbarBuilder(WidgetBuilder? builder) {
    _androidToolbarBuilder = builder;
    return this;
  }

  /// Configures the [SuperEditor] to use the given [builder] as its iOS toolbar builder.
  TestDocumentConfigurator withiOSToolbarBuilder(WidgetBuilder? builder) {
    _iOSToolbarBuilder = builder;
    return this;
  }

  /// Configures the [ThemeData] used for the [MaterialApp] that wraps
  /// the [SuperEditor].
  TestDocumentConfigurator useAppTheme(ThemeData theme) {
    _appTheme = theme;
    return this;
  }

  /// Configures the [SuperEditor] to use the given [stylesheet].
  TestDocumentConfigurator useStylesheet(Stylesheet? stylesheet) {
    _stylesheet = stylesheet;
    return this;
  }

  /// Adds the given component builders to the list of component builders that are
  /// used to render the document layout in the pumped [SuperEditor].
  TestDocumentConfigurator withAddedComponents(List<ComponentBuilder> newComponents) {
    _addedComponents.addAll(newComponents);
    return this;
  }

  /// Configures the [SuperEditor] to auto-focus when first pumped, or not.
  TestDocumentConfigurator autoFocus(bool autoFocus) {
    _autoFocus = autoFocus;
    return this;
  }

  /// Pumps a [SuperEditor] widget tree with the desired configuration, and returns
  /// a [TestDocumentContext], which includes the artifacts connected to the widget
  /// tree, e.g., the [DocumentEditor], [DocumentComposer], etc.
  Future<TestDocumentContext> pump() async {
    assert(_document != null || _existingContext != null);

    late TestDocumentContext testDocumentContext;
    if (_document != null) {
      final layoutKey = GlobalKey();
      final focusNode = _focusNode ?? FocusNode();
      final editor = DocumentEditor(document: _document!);
      final composer = DocumentComposer(initialSelection: _selection);
      // ignore: prefer_function_declarations_over_variables
      final layoutResolver = () => layoutKey.currentState as DocumentLayout;
      final commonOps = CommonEditorOperations(
        editor: editor,
        documentLayoutResolver: layoutResolver,
        composer: composer,
      );
      final editContext = EditContext(
        editor: editor,
        getDocumentLayout: layoutResolver,
        composer: composer,
        commonOps: commonOps,
      );

      testDocumentContext = TestDocumentContext._(
        focusNode: focusNode,
        layoutKey: layoutKey,
        editContext: editContext,
      );
    } else {
      testDocumentContext = _existingContext!;
    }

    final superEditor = _buildContent(
      SuperEditor(
        documentLayoutKey: testDocumentContext.layoutKey,
        editor: testDocumentContext.editContext.editor,
        composer: testDocumentContext.editContext.composer,
        focusNode: testDocumentContext.focusNode,
        inputSource: _inputSource,
        gestureMode: _gestureMode,
        androidToolbarBuilder: _androidToolbarBuilder,
        iOSToolbarBuilder: _iOSToolbarBuilder,
        stylesheet: _stylesheet,
        componentBuilders: [
          ..._addedComponents,
          ...(_componentBuilders ?? defaultComponentBuilders),
        ],
        autofocus: _autoFocus,
        scrollController: _scrollController,
      ),
    );

    await _widgetTester.pumpWidget(
      _buildWidgetTree(superEditor),
    );

    return testDocumentContext;
  }

  Widget _buildContent(Widget superEditor) {
    if (_editorSize != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: _editorSize!.width,
          maxHeight: _editorSize!.height,
        ),
        child: superEditor,
      );
    }
    return superEditor;
  }

  Widget _buildWidgetTree(Widget superEditor) {
    if (_widgetTreeBuilder != null) {
      return _widgetTreeBuilder!(superEditor);
    }
    return MaterialApp(
      theme: _appTheme,
      home: Scaffold(
        body: superEditor,
      ),
    );
  }
}

/// Must return a widget tree containing the given [superEditor]
typedef WidgetTreeBuilder = Widget Function(Widget superEditor);

class TestDocumentContext {
  const TestDocumentContext._({
    required this.focusNode,
    required this.layoutKey,
    required this.editContext,
  });

  final FocusNode focusNode;
  final GlobalKey layoutKey;
  final EditContext editContext;
}

Matcher equalsMarkdown(String markdown) => DocumentEqualsMarkdownMatcher(markdown);

class DocumentEqualsMarkdownMatcher extends Matcher {
  const DocumentEqualsMarkdownMatcher(this._expectedMarkdown);

  final String _expectedMarkdown;

  @override
  Description describe(Description description) {
    return description.add("given Document has equivalent content to the given markdown");
  }

  @override
  bool matches(covariant Object target, Map<dynamic, dynamic> matchState) {
    return _calculateMismatchReason(target, matchState) == null;
  }

  @override
  Description describeMismatch(
    covariant Object target,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    final mismatchReason = _calculateMismatchReason(target, matchState);
    if (mismatchReason != null) {
      mismatchDescription.add(mismatchReason);
    }
    return mismatchDescription;
  }

  String? _calculateMismatchReason(
    Object target,
    Map<dynamic, dynamic> matchState,
  ) {
    late Document actualDocument;
    if (target is Document) {
      actualDocument = target;
    } else {
      // If we weren't given a Document, then we expect to receive a Finder
      // that locates a SuperEditor, which contains a Document.
      if (target is! Finder) {
        return "the given target isn't a Document or a Finder: $target";
      }

      final document = SuperEditorInspector.findDocument(target);
      if (document == null) {
        return "Finder didn't match any SuperEditor widgets: $Finder";
      }
      actualDocument = document;
    }

    final actualMarkdown = serializeDocumentToMarkdown(actualDocument);
    final stringMatcher = equals(_expectedMarkdown);
    final matcherState = {};
    final matches = stringMatcher.matches(actualMarkdown, matcherState);
    if (matches) {
      // The document matches the markdown. Our matcher matches.
      return null;
    }

    return stringMatcher.describeMismatch(actualMarkdown, StringDescription(), matchState, false).toString();
  }
}

Matcher documentEquivalentTo(Document expectedDocument) => EquivalentDocumentMatcher(expectedDocument);

class EquivalentDocumentMatcher extends Matcher {
  const EquivalentDocumentMatcher(this._expectedDocument);

  final Document _expectedDocument;

  @override
  Description describe(Description description) {
    return description.add("given Document has equivalent content to expected Document");
  }

  @override
  bool matches(covariant Object target, Map<dynamic, dynamic> matchState) {
    return _calculateMismatchReason(target, matchState) == null;
  }

  @override
  Description describeMismatch(
    covariant Object target,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    final mismatchReason = _calculateMismatchReason(target, matchState);
    if (mismatchReason != null) {
      mismatchDescription.add(mismatchReason);
    }
    return mismatchDescription;
  }

  String? _calculateMismatchReason(
    Object target,
    Map<dynamic, dynamic> matchState,
  ) {
    late Document actualDocument;
    if (target is Document) {
      actualDocument = target;
    } else {
      // If we weren't given a Document, then we expect to receive a Finder
      // that locates a SuperEditor, which contains a Document.
      if (target is! Finder) {
        return "the given target isn't a Document or a Finder: $target";
      }

      final document = SuperEditorInspector.findDocument(target);
      if (document == null) {
        return "Finder didn't match any SuperEditor widgets: $Finder";
      }
      actualDocument = document;
    }

    final messages = <String>[];
    bool nodeCountMismatch = false;
    bool nodeTypeOrContentMismatch = false;

    if (_expectedDocument.nodes.length != actualDocument.nodes.length) {
      messages
          .add("expected ${_expectedDocument.nodes.length} document nodes but found ${actualDocument.nodes.length}");
      nodeCountMismatch = true;
    } else {
      messages.add("document have the same number of nodes");
    }

    final maxNodeCount = max(_expectedDocument.nodes.length, actualDocument.nodes.length);
    final nodeComparisons = List.generate(maxNodeCount, (index) => ["", "", " "]);
    for (int i = 0; i < maxNodeCount; i += 1) {
      if (i < _expectedDocument.nodes.length && i < actualDocument.nodes.length) {
        nodeComparisons[i][0] = _expectedDocument.nodes[i].runtimeType.toString();
        nodeComparisons[i][1] = actualDocument.nodes[i].runtimeType.toString();

        if (_expectedDocument.nodes[i].runtimeType != actualDocument.nodes[i].runtimeType) {
          nodeComparisons[i][2] = "Wrong Type";
          nodeTypeOrContentMismatch = true;
        } else if (!_expectedDocument.nodes[i].hasEquivalentContent(actualDocument.nodes[i])) {
          nodeComparisons[i][2] = "Different Content";
          nodeTypeOrContentMismatch = true;
        }
      } else if (i < _expectedDocument.nodes.length) {
        nodeComparisons[i][0] = _expectedDocument.nodes[i].runtimeType.toString();
        nodeComparisons[i][1] = "NA";
        nodeComparisons[i][2] = "Missing Node";
      } else if (i < actualDocument.nodes.length) {
        nodeComparisons[i][0] = "NA";
        nodeComparisons[i][1] = actualDocument.nodes[i].runtimeType.toString();
        nodeComparisons[i][2] = "Missing Node";
      }
    }

    if (nodeCountMismatch || nodeTypeOrContentMismatch) {
      String messagesList = messages.join(", ");
      messagesList += "\n";
      messagesList += const TableRenderer().render(nodeComparisons, columns: ["Expected", "Actual", "Difference"]);
      return messagesList;
    }

    return null;
  }
}
