//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { BlockNoteEditorOptions, BlockNoteSchema, User } from '@blocknote/core';
import { ExternalLinkA11yExtension } from '../extensions/external-link-a11y';
import { ExternalLinkCaptureExtension } from '../extensions/external-link-capture';
import { CollaborationCursorLabelFitExtension } from '../extensions/collaboration-cursor-label-fit';
import { filterSuggestionItems } from '@blocknote/core/extensions';
import { withCollaboration } from '@blocknote/core/yjs';
import { BlockNoteView } from '@blocknote/mantine';
import { getDefaultReactSlashMenuItems, SuggestionMenuController, useCreateBlockNote } from '@blocknote/react';
import { HocuspocusProvider } from '@hocuspocus/provider';
import {
  initializeOpBlockNoteExtensions,
  openProjectWorkPackageBlockSpec,
  openProjectWorkPackageInlineSpec,
  getOpenProjectSlashMenuItems,
  OpenProjectFormattingToolbar,
  useHashWpMenu,
} from 'op-blocknote-extensions';
import { useCallback, useEffect, useLayoutEffect, useMemo, useRef } from 'react';
import * as Y from 'yjs';
import { useBlockNoteAttachments } from '../hooks/useBlockNoteAttachments';
import { useBlockNoteLocale } from '../hooks/useBlockNoteLocale';
import { useOpTheme } from '../hooks/useOpTheme';

export interface OpBlockNoteEditorProps {
  activeUser:User;
  readOnly:boolean;
  openProjectUrl:string;
  attachmentsUploadUrl:string;
  attachmentsCollectionKey:string;
  projectId:string;
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
  projectId,
  captureExternalLinks,
  hocuspocusProvider,
  doc,
}:OpBlockNoteEditorProps) {
  const { localeString, localeDictionary } = useBlockNoteLocale(window.I18n.locale);
  const { enabled: attachmentsEnabled, uploadFile } = useBlockNoteAttachments(attachmentsCollectionKey, attachmentsUploadUrl);

  useEffect(() => {
    initializeOpBlockNoteExtensions({ baseUrl: openProjectUrl, locale: localeString, projectId });
  }, [openProjectUrl, localeString, projectId]);

  const editorParams = useMemo<Partial<BlockNoteEditorOptions<typeof schema.blockSchema, typeof schema.inlineContentSchema, typeof schema.styleSchema>>>(() => {
    const baseParams = {
      schema,
      dictionary: localeDictionary,
      ...(attachmentsEnabled && { uploadFile }),
      extensions: [
        ExternalLinkA11yExtension,
        ...(captureExternalLinks ? [ExternalLinkCaptureExtension] : []),
        ...(hocuspocusProvider ? [CollaborationCursorLabelFitExtension] : []),
      ],
    };

    if (!hocuspocusProvider) {
      return baseParams;
    }

    // Since BlockNote 0.52 a `collaboration` option passed straight to the editor is
    // ignored, and the spread keeps TypeScript from flagging it.
    return withCollaboration({
      ...baseParams,
      collaboration: {
        fragment: doc.getXmlFragment('document-store'),
        user: {
          name: activeUser.username,
          color: generateRandomColor(),
          id: activeUser.id,
        },
        // Hocuspocus types `awareness` as `Awareness | null`, BlockNote as `Awareness | undefined`.
        provider: hocuspocusProvider as { awareness?:NonNullable<HocuspocusProvider['awareness']> },
        showCursorLabels: 'activity' as const,
      },
    });
  }, [hocuspocusProvider, doc, activeUser, localeDictionary, attachmentsEnabled, uploadFile, captureExternalLinks]);

  // Create the editor exactly once per mount. `useCreateBlockNote(options, deps)` uses `deps`
  // as the sole `useMemo` key — `options` is intentionally NOT in deps. `[activeUser]` rebuilt
  // the editor (wiping `Y.UndoManager` history) whenever a fresh `activeUser` reference
  // reached this component, e.g. on Stimulus reconnect / Turbo morph.
  const editor = useCreateBlockNote(editorParams, []);
  type EditorType = typeof editor;
  const theme = useOpTheme();

  // Works around a BlockNote/Yjs bootstrap race (COMMS-909): the initial sync leaves BlockNote's
  // `data-prev-type` transition decoration stuck on the first block, so a heading renders at
  // body-text size until the next transaction clears it. Dispatch one before first paint.
  const forcedInitialBlockRefreshRef = useRef(false);
  useLayoutEffect(() => {
    if (!hocuspocusProvider || forcedInitialBlockRefreshRef.current) {
      return;
    }

    forcedInitialBlockRefreshRef.current = true;
    editor.transact((tr) => tr.setMeta('addToHistory', false));
  }, [editor, hocuspocusProvider]);

  const getCustomSlashMenuItems = useCallback((editorInstance:EditorType) => [
    ...getDefaultReactSlashMenuItems(editorInstance),
    ...getOpenProjectSlashMenuItems(editorInstance),
  ], []);
  const { getHashItems, HashWpMenu } = useHashWpMenu(editor);

  return (
    <>
      <BlockNoteView
        editor={editor}
        slashMenu={false}
        formattingToolbar={false}
        theme={theme}
        editable={!readOnly}
        className={'block-note-editor-container'}
      >
        <OpenProjectFormattingToolbar />
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
