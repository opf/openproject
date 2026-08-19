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

import { User } from '@blocknote/core/comments';
import { HocuspocusProvider } from '@hocuspocus/provider';
import { useEffect, useRef } from 'react';
import * as Y from 'yjs';
import { DocumentLoadingSkeleton } from './components/DocumentLoadingSkeleton';
import { OpBlockNoteEditor } from './components/OpBlockNoteEditor';
import { useCollaboration } from './hooks/useCollaboration';

export interface OpBlockNoteContainerProps {
  activeUser:User;
  readOnly:boolean;
  openProjectUrl:string;
  attachmentsUploadUrl:string;
  attachmentsCollectionKey:string;
  captureExternalLinks:boolean;
  hocuspocusProvider:HocuspocusProvider;
}

export default function OpBlockNoteContainer({
  activeUser,
  readOnly,
  openProjectUrl,
  attachmentsUploadUrl,
  attachmentsCollectionKey,
  captureExternalLinks,
  hocuspocusProvider,
}:OpBlockNoteContainerProps) {
  const doc:Y.Doc = hocuspocusProvider.document;
  const { isLoading, offlineMode } = useCollaboration(hocuspocusProvider);
  const hadErrorRef = useRef(false);

  useEffect(() => {
    if (offlineMode) {
      hadErrorRef.current = true;
      window.dispatchEvent(new CustomEvent('documents:connection-error'));
    } else if (hadErrorRef.current) {
      window.dispatchEvent(new CustomEvent('documents:connection-recovery'));
    }
  }, [offlineMode]);

  if (isLoading) {
    return <DocumentLoadingSkeleton />;
  }

  // Without IndexedDB offline persistence, all offline is blocking — hide the
  // editor entirely to prevent a fresh empty Y.Doc from being synced as
  // authoritative server state on reconnect.
  if (offlineMode) {
    return null;
  }

  return (
    <OpBlockNoteEditor
      activeUser={activeUser}
      readOnly={readOnly}
      openProjectUrl={openProjectUrl}
      attachmentsUploadUrl={attachmentsUploadUrl}
      attachmentsCollectionKey={attachmentsCollectionKey}
      captureExternalLinks={captureExternalLinks}
      hocuspocusProvider={hocuspocusProvider}
      doc={doc}
    />
  );
}
