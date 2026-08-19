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

import { IUploadFile } from 'core-app/core/upload/upload.service';
import { useCallback } from 'react';
import { firstValueFrom } from 'rxjs';

export interface BlockNoteAttachmentsResult {
  enabled:boolean;
  uploadFile?:(file:File) => Promise<string>;
}

export function useBlockNoteAttachments(
  attachmentsCollectionKey:string,
  attachmentsUploadUrl:string,
):BlockNoteAttachmentsResult {
  const enabled = (
    attachmentsCollectionKey !== undefined &&
    attachmentsCollectionKey !== '' &&
    attachmentsUploadUrl !== undefined &&
    attachmentsUploadUrl !== ''
  );

  const uploadFile = useCallback(async (file:File):Promise<string> => {
    const pluginContext = await window.OpenProject.getPluginContext();
    try {
      const service = pluginContext.services.attachmentsResourceService;
      const uploadFiles:IUploadFile[] = [{ file }];
      const result = await firstValueFrom(
        service.addAttachments(attachmentsCollectionKey, attachmentsUploadUrl, uploadFiles)
      );

      return result?.[0]._links.staticDownloadLocation.href ?? '';
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
    } catch (error:any) {
      const toastService = pluginContext.services.notifications;
      // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
      toastService.addError(error);

      return '';
    }
  }, [attachmentsCollectionKey, attachmentsUploadUrl]);

  if (!enabled) {
    return { enabled };
  }

  return { enabled, uploadFile };
}

export default useBlockNoteAttachments;
