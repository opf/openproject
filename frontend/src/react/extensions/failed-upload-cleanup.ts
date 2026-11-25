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

import { createExtension } from '@blocknote/core';

// A file block turns into "Loading..." when its upload starts and only renders again once
// its props change. After a failed drop or paste nothing changes, so the placeholder would
// stay stuck (https://github.com/TypeCellOS/BlockNote/issues/3246). BlockNote updates the
// block after the upload ends, hence the timeout.
export const FailedUploadCleanupExtension = createExtension(({ editor }) => ({
  key: 'failedUploadCleanup',
  mount: ({ signal }) => editor.onUploadEnd((blockId) => {
    if (!blockId) return;

    setTimeout(() => {
      const stuck = !signal.aborted && editor.domElement?.querySelector(`[data-id="${blockId}"] .bn-file-loading-preview`);
      if (stuck) editor.removeBlocks([blockId]);
    });
  }),
}))();
