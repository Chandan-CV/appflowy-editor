import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class Editor extends StatelessWidget {
  const Editor({
    super.key,
    required this.jsonString,
    required this.onEditorStateChange,
    this.editorStyle,
  });

  final Future<String> jsonString;
  final EditorStyle? editorStyle;
  final void Function(EditorState editorState) onEditorStateChange;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: jsonString,
      builder: (context, snapshot) {
        if (snapshot.hasData &&
            snapshot.connectionState == ConnectionState.done) {
          final editorState = EditorState(
            document: Document.fromJson(
              Map<String, Object>.from(
                json.decode(snapshot.data!),
              ),
            ),
          );
          editorState.logConfiguration
            ..handler = debugPrint
            ..level = LogLevel.off;
          editorState.transactionStream.listen((event) {
            if (event.$1 == TransactionTime.after) {
              onEditorStateChange(editorState);
            }
          });
          final editorScrollController = EditorScrollController(
            editorState: editorState,
            shrinkWrap: false,
          );
          if (PlatformExtension.isDesktopOrWeb) {
            return FloatingToolbar(
              items: [
                paragraphItem,
                ...headingItems,
                ...markdownFormatItems,
                quoteItem,
                bulletedListItem,
                numberedListItem,
                linkItem,
                buildTextColorItem(),
                buildHighlightColorItem(),
                ...textDirectionItems,
                ...alignmentItems,
              ],
              editorState: editorState,
              editorScrollController: editorScrollController,
              child: _buildDesktopEditor(
                context,
                editorState,
                editorScrollController,
              ),
            );
          } else if (PlatformExtension.isMobile) {
            return Column(
              children: [
                Expanded(
                  child: _buildMobileEditor(
                    context,
                    editorState,
                    editorScrollController,
                  ),
                ),
                MobileToolbar(
                  editorState: editorState,
                  toolbarItems: [
                    textDecorationMobileToolbarItem,
                    buildTextAndBackgroundColorMobileToolbarItem(),
                    headingMobileToolbarItem,
                    todoListMobileToolbarItem,
                    listMobileToolbarItem,
                    linkMobileToolbarItem,
                    quoteMobileToolbarItem,
                    dividerMobileToolbarItem,
                    codeMobileToolbarItem,
                  ],
                ),
              ],
            );
          }
        }
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Widget _buildMobileEditor(
    BuildContext context,
    EditorState editorState,
    EditorScrollController? editorScrollController,
  ) {
    return AppFlowyEditor(
      editorStyle: const EditorStyle.mobile(),
      editorState: editorState,
      editorScrollController: editorScrollController,
    );
  }

  Widget _buildDesktopEditor(
    BuildContext context,
    EditorState editorState,
    EditorScrollController? editorScrollController,
  ) {
    final customBlockComponentBuilders = {
      ...standardBlockComponentBuilderMap,
      ImageBlockKeys.type: ImageBlockComponentBuilder(
        showMenu: true,
        menuBuilder: (node, _) {
          return const Positioned(
            right: 10,
            child: Text('Sample Menu'),
          );
        },
      )
    };
    return AppFlowyEditor(
      editorState: editorState,
      shrinkWrap: true,
      editorScrollController: editorScrollController,
      blockComponentBuilders: customBlockComponentBuilders,
      commandShortcutEvents: [
        customToggleHighlightCommand(
          style: ToggleColorsStyle(
            highlightColor: Theme.of(context).highlightColor,
          ),
        ),
        ...[
          ...standardCommandShortcutEvents
            ..removeWhere(
              (el) => el == toggleHighlightCommand,
            ),
        ],
        ...findAndReplaceCommands(
          context: context,
          localizations: FindReplaceLocalizations(
            find: 'Find',
            previousMatch: 'Previous match',
            nextMatch: 'Next match',
            close: 'Close',
            replace: 'Replace',
            replaceAll: 'Replace all',
          ),
        ),
      ],
      characterShortcutEvents: standardCharacterShortcutEvents,
    );
  }
}
