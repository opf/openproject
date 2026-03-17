import { BlockNoteSchema } from "@blocknote/core";
import { filterSuggestionItems } from "@blocknote/core/extensions";
import "@blocknote/core/fonts/inter.css";
import { BlockNoteView } from "@blocknote/mantine";
import "@blocknote/mantine/style.css";
import {
  getDefaultReactSlashMenuItems,
  SuggestionMenuController,
  useCreateBlockNote,
} from "@blocknote/react";
import {
  initializeOpBlockNoteExtensions,
  openProjectWorkPackageBlockSpec,
  inlineWorkPackageSpec,
  inlineWorkPackageSlashMenu,
  InlineWorkPackageClipboardExtension,
  setLastPasteHtml,
} from "../lib";
import { useEffect, useRef } from "react";
import "./fetchOverride";

const schema = BlockNoteSchema.create().extend({
  blockSpecs: {
    openProjectWorkPackage: openProjectWorkPackageBlockSpec(),
  },
  inlineContentSpecs: {
    inlineWorkPackage: inlineWorkPackageSpec,
  },
});

type EditorType = typeof schema.BlockNoteEditor;

export default function App() {
  const editorContainerRef = useRef<HTMLDivElement>(null);

  const editor = useCreateBlockNote({
    schema,
    _tiptapOptions: {
      extensions: [InlineWorkPackageClipboardExtension],
    },
  });

  useEffect(() => {
    initializeOpBlockNoteExtensions({
      baseUrl: "http://localhost:3000",
      locale: "en",
    });
  }, []);

  useEffect(() => {
    const container = editorContainerRef.current;
    if (!container) return;

    const onPaste = (e: ClipboardEvent) => {
      const html = e.clipboardData?.getData('text/html') ?? '';
      if (html.includes('data-inline-wp')) {
        setLastPasteHtml(html);
      }
    };

    container.addEventListener('paste', onPaste, { capture: true });
    return () => container.removeEventListener('paste', onPaste, { capture: true });
  }, []);

  const getCustomSlashMenuItems = (editorInstance: EditorType) => [
    ...getDefaultReactSlashMenuItems(editorInstance),
    inlineWorkPackageSlashMenu(editorInstance as any),
  ];

  return (
    <div ref={editorContainerRef}>
      <BlockNoteView editor={editor} slashMenu={false}>
        <SuggestionMenuController
          triggerCharacter="/"
          getItems={async (query: string) =>
            filterSuggestionItems(getCustomSlashMenuItems(editor), query)
          }
        />
      </BlockNoteView>
    </div>
  );
}