/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { BlockNoteEditorOptions, BlockNoteSchema } from '@blocknote/core';
import { ExternalLinkA11yExtension } from '../extensions/external-link-a11y';
import { ExternalLinkCaptureExtension } from '../extensions/external-link-capture';
import { User } from '@blocknote/core/comments';
import { filterSuggestionItems } from '@blocknote/core/extensions';
import { BlockNoteView } from '@blocknote/mantine';
import { getDefaultReactSlashMenuItems, SuggestionMenuController, useCreateBlockNote } from '@blocknote/react';
import { HocuspocusProvider } from '@hocuspocus/provider';
import {
  initializeOpBlockNoteExtensions,
  openProjectWorkPackageBlockSpec,
  openProjectWorkPackageInlineSpec,
  workPackageSlashMenu,
  useOpBlockNoteExtensions,
  PasteDeduplicateInstanceIdsExtension,
  useHashWpMenu,
} from 'op-blocknote-extensions';
import { useCallback, useEffect, useMemo } from 'react';
import * as Y from 'yjs';
import { useBlockNoteAttachments } from '../hooks/useBlockNoteAttachments';
import { useBlockNoteLocale } from '../hooks/useBlockNoteLocale';
import { useOpTheme } from '../hooks/useOpTheme';

interface CollaborativeUser {
  name:string;
  color:string;
}

export interface OpBlockNoteEditorProps {
  activeUser:User;
  readOnly:boolean;
  openProjectUrl:string;
  attachmentsUploadUrl:string;
  attachmentsCollectionKey:string;
  captureExternalLinks:boolean;
  hocuspocusProvider?:HocuspocusProvider;
  doc:Y.Doc;
}

const schema = BlockNoteSchema.create().extend({
  blockSpecs: {
    openProjectWorkPackageBlock: openProjectWorkPackageBlockSpec(),
  },
  inlineContentSpecs: {
    openProjectWorkPackageInline: openProjectWorkPackageInlineSpec,
  },
});

function generateRandomColor() {
  return '#' + Math.floor(Math.random() * 16777215).toString(16).padStart(6, '0');
}

export function OpBlockNoteEditor({
  activeUser,
  readOnly,
  openProjectUrl,
  attachmentsUploadUrl,
  attachmentsCollectionKey,
  captureExternalLinks,
  hocuspocusProvider,
  doc,
}:OpBlockNoteEditorProps) {
  const { localeString, localeDictionary } = useBlockNoteLocale(window.I18n.locale);
  const { enabled: attachmentsEnabled, uploadFile } = useBlockNoteAttachments(attachmentsCollectionKey, attachmentsUploadUrl);

  useEffect(() => {
    initializeOpBlockNoteExtensions({ baseUrl: openProjectUrl, locale: localeString });
  }, [openProjectUrl, localeString]);

  const editorParams = useMemo<Partial<BlockNoteEditorOptions<typeof schema.blockSchema, typeof schema.inlineContentSchema, typeof schema.styleSchema>>>(() => {
    return {
      schema,
      // BlockNote 0.51 tightened `collaboration.provider` to a non-null shape
      // and `awareness: Awareness | undefined` (vs Hocuspocus's
      // `Awareness | null`). Omit the whole `collaboration` block when no
      // provider is wired up; cast the provider at the boundary otherwise.
      ...(hocuspocusProvider && {
        collaboration: {
          fragment: doc.getXmlFragment('document-store'),
          user: {
            name: activeUser.username,
            color: generateRandomColor(),
            id: activeUser.id,
          } as unknown as CollaborativeUser,
          provider: hocuspocusProvider as unknown as { awareness?:NonNullable<HocuspocusProvider['awareness']> },
          showCursorLabels: 'activity' as const,
        },
      }),
      dictionary: localeDictionary,
      ...(attachmentsEnabled && { uploadFile }),
      extensions: [
        PasteDeduplicateInstanceIdsExtension,
        ExternalLinkA11yExtension,
        ...(captureExternalLinks ? [ExternalLinkCaptureExtension] : []),
      ],
    };
  }, [hocuspocusProvider, doc, activeUser, localeDictionary, attachmentsEnabled, uploadFile, captureExternalLinks]);

  // Create the editor exactly once per mount. `useCreateBlockNote(options, deps)` uses `deps`
  // as the sole `useMemo` key — `options` is intentionally NOT in deps. `[activeUser]` rebuilt
  // the editor (wiping `Y.UndoManager` history) whenever a fresh `activeUser` reference
  // reached this component, e.g. on Stimulus reconnect / Turbo morph.
  const editor = useCreateBlockNote(editorParams, []);
  useOpBlockNoteExtensions(editor);
  type EditorType = typeof editor;
  const theme = useOpTheme();

  const getCustomSlashMenuItems = useCallback((editorInstance:EditorType) => [
    ...getDefaultReactSlashMenuItems(editorInstance),
    workPackageSlashMenu(editorInstance),
  ], []);
  const { getHashItems, HashWpMenu } = useHashWpMenu(editor);

  return (
    <>
      <BlockNoteView
        editor={editor}
        slashMenu={false}
        theme={theme}
        editable={!readOnly}
        className={'block-note-editor-container'}
      >
        <SuggestionMenuController
          triggerCharacter="/"
          getItems={async (query:string) => Promise.resolve(filterSuggestionItems(getCustomSlashMenuItems(editor), query))}
        />
        <SuggestionMenuController
          triggerCharacter="#"
          getItems={getHashItems}
          suggestionMenuComponent={HashWpMenu}
        />
      </BlockNoteView>
    </>
  );
}
