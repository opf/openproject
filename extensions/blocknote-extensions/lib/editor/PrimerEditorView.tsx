import type { BlockSchema, InlineContentSchema, StyleSchema } from '@blocknote/core';
import { filterSuggestionItems, getDefaultSlashMenuItems } from '@blocknote/core/extensions';
import { BlockNoteViewRaw, type BlockNoteViewProps, ComponentsContext, GridSuggestionMenuController, SuggestionMenuController } from '@blocknote/react';
import { getOpenProjectSlashMenuItems, OpenProjectHashMenu } from '../index';
import { EditorTranslationContext, type EditorTranslate, useEditorTranslation } from './editorTranslations';
import { primerEditorComponents } from './primerEditorComponents';
import { PrimerEmojiPicker } from './PrimerEmojiPicker';
import { PrimerFilePanel } from './PrimerFilePanel';
import { PrimerFormattingToolbar } from './PrimerFormattingToolbar';
import { PrimerLinkToolbar } from './PrimerLinkToolbar';
import { PrimerSideMenuController } from './PrimerSideMenu';
import { PrimerSlashMenu, withPrimerIcon } from './PrimerSlashMenu';
import { PrimerTableHandles } from './PrimerTableHandles';

export function PrimerEditorView<B extends BlockSchema, I extends InlineContentSchema, S extends StyleSchema>({
  editor, editable = true, theme, translate,
}:Pick<BlockNoteViewProps<B, I, S>, 'editor' | 'editable' | 'theme'> & { translate?:EditorTranslate }) {
  const defaultTranslate = useEditorTranslation();
  return (
    <EditorTranslationContext.Provider value={translate ?? defaultTranslate}>
      <ComponentsContext.Provider value={primerEditorComponents}>
        <BlockNoteViewRaw editor={editor} theme={theme} editable={editable} className="block-note-editor-container"
          slashMenu={false} sideMenu={false} tableHandles={false} formattingToolbar={false}
          linkToolbar={false} filePanel={false} emojiPicker={false}>
          <PrimerFormattingToolbar />
          <PrimerLinkToolbar />
          {editable && <PrimerFilePanel />}
          <PrimerSideMenuController />
          <PrimerTableHandles />
          <SuggestionMenuController triggerCharacter="/" suggestionMenuComponent={PrimerSlashMenu}
            getItems={(query) => Promise.resolve(filterSuggestionItems([
              ...getDefaultSlashMenuItems(editor).map(withPrimerIcon), ...getOpenProjectSlashMenuItems(editor),
            ], query))} />
          {editable && <GridSuggestionMenuController triggerCharacter=":" columns={10} minQueryLength={2}
            gridSuggestionMenuComponent={PrimerEmojiPicker} />}
          <OpenProjectHashMenu />
        </BlockNoteViewRaw>
      </ComponentsContext.Provider>
    </EditorTranslationContext.Provider>
  );
}
