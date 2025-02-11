import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_robots/flutter_test_robots.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';

import '../../../test_tools.dart';
import '../../supereditor_test_tools.dart';
import '../../test_documents.dart';

void main() {
  group("SuperEditor stable tags >", () {
    group("composing >", () {
      testWidgetsOnAllPlatforms("can start at the beginning of a paragraph", (tester) async {
        await _pumpTestEditor(
          tester,
          singleParagraphEmptyDoc(),
        );
        await tester.placeCaretInParagraph("1", 0);

        // Compose a stable tag.
        await tester.typeImeText("@john");

        // Ensure that the tag has a composing attribution.
        final text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "@john");
        expect(
          text.getAttributedRange({stableTagComposingAttribution}, 0),
          const SpanRange(start: 0, end: 4),
        );
      });

      testWidgetsOnAllPlatforms("can start between words", (tester) async {
        await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText("before  after"),
              ),
            ],
          ),
        );

        // Place the caret at "before |"
        await tester.placeCaretInParagraph("1", 7);

        // Compose a stable tag.
        await tester.typeImeText("@john");

        // Ensure that the tag has a composing attribution.
        final text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "before @john after");
        expect(
          text.getAttributedRange({stableTagComposingAttribution}, 7),
          const SpanRange(start: 7, end: 11),
        );
      });

      testWidgetsOnAllPlatforms("by default does not continue after a space", (tester) async {
        await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText("before "),
              ),
            ],
          ),
        );

        // Place the caret at "before |"
        await tester.placeCaretInParagraph("1", 7);

        // Compose a stable tag.
        await tester.typeImeText("@john after");

        // Ensure that there's no more composing attribution because the tag
        // should have been committed.
        final text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "before @john after");
        expect(
          text.getAttributionSpansInRange(
            attributionFilter: (attribution) => attribution == stableTagComposingAttribution,
            range: const SpanRange(start: 0, end: 18),
          ),
          isEmpty,
        );
      });

      testWidgetsOnAllPlatforms("can be configured to continue after a space", (tester) async {
        await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText("before "),
              ),
            ],
          ),
          const TagRule(trigger: "@"),
        );

        // Place the caret at "before |"
        await tester.placeCaretInParagraph("1", 7);

        // Compose a stable tag.
        await tester.typeImeText("@john");

        // Ensure that we started composing a tag before adding a space.
        var text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "before @john");
        expect(
          text.getAttributedRange({stableTagComposingAttribution}, 7),
          const SpanRange(start: 7, end: 11),
        );

        await tester.typeImeText(" after");

        // Ensure that the composing attribution continues after the space.
        text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "before @john after");
        expect(
          text.getAttributedRange({stableTagComposingAttribution}, 7),
          const SpanRange(start: 7, end: 17),
        );
      });

      testWidgetsOnAllPlatforms("continues when user expands the selection upstream", (tester) async {
        await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText("before "),
              ),
              ParagraphNode(
                id: "2",
                text: AttributedText(),
              ),
            ],
          ),
        );

        // Place the caret at "before |"
        await tester.placeCaretInParagraph("1", 7);

        // Compose a stable tag.
        await tester.typeImeText("@john");

        // Expand the selection to "before @joh|n|"
        await tester.pressShiftLeftArrow();
        expect(
          SuperEditorInspector.findDocumentSelection(),
          const DocumentSelection(
            base: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 12),
            ),
            extent: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 11),
            ),
          ),
        );

        // Ensure we're still composing
        AttributedText text = SuperEditorInspector.findTextInParagraph("1");
        expect(
          text.getAttributedRange({stableTagComposingAttribution}, 7),
          const SpanRange(start: 7, end: 11),
        );

        // Expand the selection to "before |@john|"
        await tester.pressShiftLeftArrow();
        await tester.pressShiftLeftArrow();
        await tester.pressShiftLeftArrow();
        await tester.pressShiftLeftArrow();

        // Ensure we're still composing
        text = SuperEditorInspector.findTextInParagraph("1");
        expect(
          text.getAttributedRange({stableTagComposingAttribution}, 7),
          const SpanRange(start: 7, end: 11),
        );

        // Expand the selection to "befor|e @john|"
        await tester.pressShiftLeftArrow();
        await tester.pressShiftLeftArrow();

        // Ensure we're still composing
        text = SuperEditorInspector.findTextInParagraph("1");
        expect(
          text.getAttributedRange({stableTagComposingAttribution}, 7),
          const SpanRange(start: 7, end: 11),
        );
      });

      testWidgetsOnAllPlatforms("continues when user expands the selection downstream", (tester) async {
        await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText("before  after"),
              ),
              ParagraphNode(
                id: "2",
                text: AttributedText(),
              ),
            ],
          ),
        );

        // Place the caret at "before | after"
        await tester.placeCaretInParagraph("1", 7);

        // Compose a stable tag.
        await tester.typeImeText("@john");

        // Move the caret to "before @|john".
        await tester.pressLeftArrow();
        await tester.pressLeftArrow();
        await tester.pressLeftArrow();
        await tester.pressLeftArrow();

        // Expand the selection to "before @|john a|fter"
        await tester.pressShiftRightArrow();
        await tester.pressShiftRightArrow();
        await tester.pressShiftRightArrow();
        await tester.pressShiftRightArrow();
        await tester.pressShiftRightArrow();
        await tester.pressShiftRightArrow();
        expect(
          SuperEditorInspector.findDocumentSelection(),
          const DocumentSelection(
            base: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 8),
            ),
            extent: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 14),
            ),
          ),
        );

        // Ensure we're still composing
        AttributedText text = SuperEditorInspector.findTextInParagraph("1");
        expect(
          text.getAttributedRange({stableTagComposingAttribution}, 7),
          const SpanRange(start: 7, end: 11),
        );
      });

      testWidgetsOnAllPlatforms("cancels composing when the user presses ESC", (tester) async {
        await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText("before "),
              ),
            ],
          ),
        );

        // Place the caret at "before |"
        await tester.placeCaretInParagraph("1", 7);

        // Start composing a stable tag.
        await tester.typeImeText("@");

        // Ensure that we're composing.
        var text = SuperEditorInspector.findTextInParagraph("1");
        expect(
          text.getAttributedRange({stableTagComposingAttribution}, 7),
          const SpanRange(start: 7, end: 7),
        );

        // Cancel composing.
        await tester.pressEscape();

        // Ensure that the composing was cancelled.
        text = SuperEditorInspector.findTextInParagraph("1");
        expect(
          text.getAttributionSpansInRange(
            attributionFilter: (attribution) => attribution == stableTagComposingAttribution,
            range: const SpanRange(start: 0, end: 7),
          ),
          isEmpty,
        );
        expect(
          text.getAttributedRange({stableTagCancelledAttribution}, 7),
          const SpanRange(start: 7, end: 7),
        );

        // Start typing again.
        await tester.typeImeText("j");

        // Ensure that we didn't start composing again.
        text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "before @j");
        expect(
          text.getAttributionSpansInRange(
            attributionFilter: (attribution) => attribution == stableTagComposingAttribution,
            range: const SpanRange(start: 0, end: 8),
          ),
          isEmpty,
        );
        expect(
          text.getAttributedRange({stableTagCancelledAttribution}, 7),
          const SpanRange(start: 7, end: 7),
        );

        // Add a space, cause the tag to end.
        await tester.typeImeText(" ");

        // Ensure that the cancelled tag wasn't committed, and didn't start composing again.
        text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "before @j ");
        expect(
          text.getAttributionSpansInRange(
            attributionFilter: (attribution) => attribution == stableTagComposingAttribution,
            range: const SpanRange(start: 0, end: 9),
          ),
          isEmpty,
        );
        expect(
          text.getAttributionSpansInRange(
            attributionFilter: (attribution) => attribution is CommittedStableTagAttribution,
            range: const SpanRange(start: 0, end: 9),
          ),
          isEmpty,
        );
        expect(
          text.getAttributedRange({stableTagCancelledAttribution}, 7),
          const SpanRange(start: 7, end: 7),
        );
      });
    });

    group("commits >", () {
      testWidgetsOnAllPlatforms("at the beginning of a paragraph", (tester) async {
        await _pumpTestEditor(
          tester,
          singleParagraphEmptyDoc(),
        );

        // Place the caret in the empty paragraph.
        await tester.placeCaretInParagraph("1", 0);

        // Compose a stable tag.
        await tester.typeImeText("@john after");

        // Ensure that only the stable tag is attributed as a stable tag.
        final text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "@john after");
        expect(
          text.getAttributedRange({const CommittedStableTagAttribution("john")}, 0),
          const SpanRange(start: 0, end: 4),
        );
      });

      testWidgetsOnAllPlatforms("after existing text", (tester) async {
        await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText("before "),
              ),
            ],
          ),
        );

        // Place the caret at "before |"
        await tester.placeCaretInParagraph("1", 7);

        // Compose a stable tag.
        await tester.typeImeText("@john after");

        // Ensure that only the stable tag is attributed as a stable tag.
        final text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "before @john after");
        expect(
          text.getAttributedRange({const CommittedStableTagAttribution("john")}, 7),
          const SpanRange(start: 7, end: 11),
        );
      });

      testWidgetsOnAllPlatforms("at end of text when user moves the caret", (tester) async {
        await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText("before "),
              ),
              ParagraphNode(
                id: "2",
                text: AttributedText(),
              ),
            ],
          ),
        );

        // Place the caret at "before |"
        await tester.placeCaretInParagraph("1", 7);

        // Compose a stable tag.
        await tester.typeImeText("@john");

        // Move the selection somewhere else.
        await tester.placeCaretInParagraph("2", 0);
        expect(
          SuperEditorInspector.findDocumentSelection()!.extent,
          const DocumentPosition(
            nodeId: "2",
            nodePosition: TextNodePosition(offset: 0),
          ),
        );

        // Ensure that the tag was submitted.
        final text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "before @john");
        expect(
          text.getAttributedRange({const CommittedStableTagAttribution("john")}, 7),
          const SpanRange(start: 7, end: 11),
        );
      });

      testWidgetsOnAllPlatforms("when upstream selection collapses outside of tag", (tester) async {
        await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText("before "),
              ),
              ParagraphNode(
                id: "2",
                text: AttributedText(),
              ),
            ],
          ),
        );

        // Place the caret at "before |"
        await tester.placeCaretInParagraph("1", 7);

        // Compose a stable tag.
        await tester.typeImeText("@john");

        // Expand the selection to "befor|e @john|"
        await tester.pressShiftLeftArrow();
        await tester.pressShiftLeftArrow();
        await tester.pressShiftLeftArrow();
        await tester.pressShiftLeftArrow();
        await tester.pressShiftLeftArrow();
        await tester.pressShiftLeftArrow();
        await tester.pressShiftLeftArrow();

        // Collapse the selection to the upstream position.
        await tester.pressLeftArrow();

        // Ensure that the stable tag was submitted.
        final text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "before @john");
        expect(
          text.getAttributedRange({const CommittedStableTagAttribution("john")}, 7),
          const SpanRange(start: 7, end: 11),
        );
      });

      testWidgetsOnAllPlatforms("when downstream selection collapses outside of tag", (tester) async {
        await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText("before  after"),
              ),
              ParagraphNode(
                id: "2",
                text: AttributedText(),
              ),
            ],
          ),
        );

        // Place the caret at "before | after"
        await tester.placeCaretInParagraph("1", 7);

        // Compose a stable tag.
        await tester.typeImeText("@john");

        // Move caret to "before @|john after"
        await tester.pressLeftArrow();
        await tester.pressLeftArrow();
        await tester.pressLeftArrow();
        await tester.pressLeftArrow();

        // Expand the selection to "before @|john a|fter"
        await tester.pressShiftRightArrow();
        await tester.pressShiftRightArrow();
        await tester.pressShiftRightArrow();
        await tester.pressShiftRightArrow();
        await tester.pressShiftRightArrow();
        await tester.pressShiftRightArrow();

        // Collapse the selection to the downstream position.
        await tester.pressRightArrow();

        // Ensure that the stable tag was submitted.
        final text = SuperEditorInspector.findTextInParagraph("1");
        expect(text.text, "before @john after");
        expect(
          text.getAttributedRange({const CommittedStableTagAttribution("john")}, 7),
          const SpanRange(start: 7, end: 11),
        );
      });
    });

    group("committed >", () {
      testWidgetsOnAllPlatforms("prevents user tapping to place caret in tag", (tester) async {
        await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText("before "),
              ),
            ],
          ),
        );

        // Place the caret at "before |"
        await tester.placeCaretInParagraph("1", 7);

        // Compose and submit a stable tag.
        await tester.typeImeText("@john after");

        // Tap near the end of the tag.
        await tester.placeCaretInParagraph("1", 10);

        // Ensure that the caret was pushed beyond the end of the tag.
        expect(
          SuperEditorInspector.findDocumentSelection(),
          const DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 12),
            ),
          ),
        );

        // Tap near the beginning of the tag.
        await tester.placeCaretInParagraph("1", 8);

        // Ensure that the caret was pushed beyond the beginning of the tag.
        expect(
          SuperEditorInspector.findDocumentSelection(),
          const DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 7),
            ),
          ),
        );
      });

      testWidgetsOnAllPlatforms("selects entire tag when double tapped", (tester) async {
        await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText("before "),
              ),
            ],
          ),
        );

        // Place the caret at "before |"
        await tester.placeCaretInParagraph("1", 7);

        // Compose and submit a stable tag.
        await tester.typeImeText("@john after");

        // Double tap on "john"
        await tester.doubleTapInParagraph("1", 10);

        // Ensure that the selection surrounds the full tag, including the "@"
        expect(
          SuperEditorInspector.findDocumentSelection(),
          const DocumentSelection(
            base: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 7),
            ),
            extent: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 12),
            ),
          ),
        );
      });

      testWidgetsOnAllPlatforms("pushes caret downstream around the tag", (tester) async {
        await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText("before "),
              ),
            ],
          ),
        );

        // Place the caret at "before |"
        await tester.placeCaretInParagraph("1", 7);

        // Compose and submit a stable tag.
        await tester.typeImeText("@john after");

        // Place the caret at "befor|e @john after"
        await tester.placeCaretInParagraph("1", 5);

        // Push the caret downstream until we push one character into the tag.
        await tester.pressRightArrow();
        await tester.pressRightArrow();
        await tester.pressRightArrow();

        // Ensure that the caret was pushed beyond the end of the tag.
        expect(
          SuperEditorInspector.findDocumentSelection(),
          const DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 12),
            ),
          ),
        );
      });

      testWidgetsOnAllPlatforms("pushes caret upstream around the tag", (tester) async {
        await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText("before "),
              ),
            ],
          ),
        );

        // Place the caret at "before |"
        await tester.placeCaretInParagraph("1", 7);

        // Compose and submit a stable tag.
        await tester.typeImeText("@john after");

        // Place the caret at "before @john a|fter"
        await tester.placeCaretInParagraph("1", 14);

        // Push the caret upstream until we push one character into the tag.
        await tester.pressLeftArrow();
        await tester.pressLeftArrow();
        await tester.pressLeftArrow();

        // Ensure that the caret pushed beyond the beginning of the tag.
        expect(
          SuperEditorInspector.findDocumentSelection(),
          const DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 7),
            ),
          ),
        );
      });

      testWidgetsOnAllPlatforms("pushes expanding downstream selection around the tag", (tester) async {
        await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText("before "),
              ),
            ],
          ),
        );

        // Place the caret at "before |"
        await tester.placeCaretInParagraph("1", 7);

        // Compose and submit a stable tag.
        await tester.typeImeText("@john after");

        // Place the caret at "befor|e @john after"
        await tester.placeCaretInParagraph("1", 5);

        // Expand downstream until we push one character into the tag.
        await tester.pressShiftRightArrow();
        await tester.pressShiftRightArrow();
        await tester.pressShiftRightArrow();

        // Ensure that the extent was pushed beyond the end of the tag.
        expect(
          SuperEditorInspector.findDocumentSelection(),
          const DocumentSelection(
            base: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 5),
            ),
            extent: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 12),
            ),
          ),
        );
      });

      testWidgetsOnAllPlatforms("pushes expanding upstream selection around the tag", (tester) async {
        await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText("before "),
              ),
            ],
          ),
        );

        // Place the caret at "before |"
        await tester.placeCaretInParagraph("1", 7);

        // Compose and submit a stable tag.
        await tester.typeImeText("@john after");

        // Place the caret at "before @john a|fter"
        await tester.placeCaretInParagraph("1", 14);

        // Expand upstream until we push one character into the tag.
        await tester.pressShiftLeftArrow();
        await tester.pressShiftLeftArrow();
        await tester.pressShiftLeftArrow();

        // Ensure that the extent was pushed beyond the beginning of the tag.
        expect(
          SuperEditorInspector.findDocumentSelection(),
          const DocumentSelection(
            base: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 14),
            ),
            extent: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 7),
            ),
          ),
        );
      });

      testWidgetsOnAllPlatforms("deletes entire tag when deleting a character upstream", (tester) async {
        await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText("before "),
              ),
            ],
          ),
        );

        // Place the caret at "before |"
        await tester.placeCaretInParagraph("1", 7);

        // Compose and submit a stable tag.
        await tester.typeImeText("@john after");

        // Place the caret at "before @john| after"
        await tester.placeCaretInParagraph("1", 12);

        // Press BACKSPACE to delete a character upstream.
        await tester.pressBackspace();

        // Ensure that the entire user tag was deleted.
        expect(SuperEditorInspector.findTextInParagraph("1").text, "before  after");
        expect(
          SuperEditorInspector.findDocumentSelection(),
          const DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 7),
            ),
          ),
        );
      });

      testWidgetsOnAllPlatforms("deletes entire tag when deleting a character downstream", (tester) async {
        await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText("before "),
              ),
            ],
          ),
        );

        // Place the caret at "before |"
        await tester.placeCaretInParagraph("1", 7);

        // Compose and submit a stable tag.
        await tester.typeImeText("@john after");

        // Place the caret at "before |@john after"
        await tester.placeCaretInParagraph("1", 7);

        // Press DELETE to delete a character downstream.
        await tester.pressDelete();

        // Ensure that the entire user tag was deleted.
        expect(SuperEditorInspector.findTextInParagraph("1").text, "before  after");
        expect(
          SuperEditorInspector.findDocumentSelection(),
          const DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 7),
            ),
          ),
        );
      });

      testWidgetsOnAllPlatforms("deletes second tag and leaves first tag alone", (tester) async {
        await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText(),
              ),
            ],
          ),
        );

        await tester.placeCaretInParagraph("1", 0);

        // Compose two tags within text
        await tester.typeImeText("one @john two @sally three");

        // Place the caret at "one @john two @sally| three"
        await tester.placeCaretInParagraph("1", 20);

        // Delete the 2nd tag.
        await tester.pressBackspace();

        // Ensure the 2nd tag was deleted, and the 1st tag remains.
        expect(SuperEditorInspector.findTextInParagraph("1").text, "one @john two  three");
        expect(
          SuperEditorInspector.findDocumentSelection(),
          const DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 14),
            ),
          ),
        );
      });

      testWidgetsOnAllPlatforms("deletes multiple tags when partially selected in the same node", (tester) async {
        final context = await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText("one "),
              ),
            ],
          ),
        );

        // Place the caret at "one |"
        await tester.placeCaretInParagraph("1", 4);

        // Compose and submit two stable tags.
        await tester.typeImeText("@john two @sally three");

        // Expand the selection "one @jo|hn two @sa|lly three"
        (context.findEditContext().composer as MutableDocumentComposer).setSelectionWithReason(
          const DocumentSelection(
            base: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 7),
            ),
            extent: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 17),
            ),
          ),
          SelectionReason.userInteraction,
        );

        // Delete the selected content, which will leave two partial user tags.
        await tester.pressBackspace();

        // Ensure that both user tags were completely deleted.
        expect(SuperEditorInspector.findTextInParagraph("1").text, "one  three");
        expect(
          SuperEditorInspector.findDocumentSelection(),
          const DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 4),
            ),
          ),
        );
      });

      testWidgetsOnAllPlatforms("deletes multiple tags when partially selected across multiple nodes", (tester) async {
        final context = await _pumpTestEditor(
          tester,
          MutableDocument(
            nodes: [
              ParagraphNode(
                id: "1",
                text: AttributedText(),
              ),
              ParagraphNode(
                id: "2",
                text: AttributedText(),
              ),
            ],
          ),
        );

        // Place the caret in the first paragraph and insert a user tag.
        await tester.placeCaretInParagraph("1", 0);
        await tester.typeImeText("one @john two");

        // Move the caret to the second paragraph and insert a second user tag.
        await tester.placeCaretInParagraph("2", 0);
        await tester.typeImeText("three @sally four");

        // Expand the selection to "one @jo|hn two\nthree @sa|lly three"
        (context.findEditContext().composer as MutableDocumentComposer).setSelectionWithReason(
          const DocumentSelection(
            base: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 7),
            ),
            extent: DocumentPosition(
              nodeId: "2",
              nodePosition: TextNodePosition(offset: 9),
            ),
          ),
          SelectionReason.userInteraction,
        );

        // Delete the selected content, which will leave two partial user tags.
        await tester.pressBackspace();

        // Ensure that both user tags were completely deleted.
        expect(SuperEditorInspector.findTextInParagraph("1").text, "one  four");
        expect(
          SuperEditorInspector.findDocumentSelection(),
          const DocumentSelection.collapsed(
            position: DocumentPosition(
              nodeId: "1",
              nodePosition: TextNodePosition(offset: 4),
            ),
          ),
        );
      });
    });
  });
}

Future<TestDocumentContext> _pumpTestEditor(
  WidgetTester tester,
  MutableDocument document, [
  TagRule tagRule = userTagRule,
]) async {
  return await tester
      .createDocument()
      .withCustomContent(document)
      .withPlugin(StableTagPlugin(
        tagRule: tagRule,
      ))
      .pump();
}
