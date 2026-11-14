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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { User } from '@blocknote/core';
import { HocuspocusProvider } from '@hocuspocus/provider';
import * as Y from 'yjs';
import { DocumentLoadingSkeleton } from './components/DocumentLoadingSkeleton';
import { OpBlockNoteEditor } from './components/OpBlockNoteEditor';
import { useCollaboration } from './hooks/useCollaboration';
import { useConnectionEvents } from './hooks/useConnectionEvents';

export interface OpBlockNoteContainerProps {
  activeUser:User;
  readOnly:boolean;
  openProjectUrl:string;
  attachmentsUploadUrl:string;
  attachmentsCollectionKey:string;
  projectId:string;
  captureExternalLinks:boolean;
  hocuspocusProvider:HocuspocusProvider;
}

export default function OpBlockNoteContainer({
  activeUser,
  readOnly,
  openProjectUrl,
  attachmentsUploadUrl,
  attachmentsCollectionKey,
  projectId,
  captureExternalLinks,
  hocuspocusProvider,
}:OpBlockNoteContainerProps) {
  const doc:Y.Doc = hocuspocusProvider.document;
  const { isLoading, offlineMode, blockingOffline } = useCollaboration(hocuspocusProvider);

  useConnectionEvents({ offlineMode, blockingOffline });

  if (isLoading) {
    return <DocumentLoadingSkeleton />;
  }

  // An unverified empty document must not mount; it would later be merged into the real one.
  if (blockingOffline) {
    return null;
  }

  return (
    <OpBlockNoteEditor
      activeUser={activeUser}
      readOnly={readOnly}
      openProjectUrl={openProjectUrl}
      attachmentsUploadUrl={attachmentsUploadUrl}
      attachmentsCollectionKey={attachmentsCollectionKey}
      projectId={projectId}
      captureExternalLinks={captureExternalLinks}
      hocuspocusProvider={hocuspocusProvider}
      doc={doc}
    />
  );
}
