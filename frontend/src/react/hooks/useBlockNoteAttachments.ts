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
import { useAttachmentValidation } from './useAttachmentValidation';

export interface BlockNoteAttachmentsResult {
  enabled:boolean;
  uploadFile?:(file:File, blockId?:string) => Promise<string>;
}

export interface EditorHandle {
  removeBlocks:(ids:string[]) => void;
}

export function useBlockNoteAttachments(
  attachmentsCollectionKey:string,
  attachmentsUploadUrl:string,
  getEditor?:() => EditorHandle | null,
):BlockNoteAttachmentsResult {
  const enabled = (
    attachmentsCollectionKey !== undefined &&
    attachmentsCollectionKey !== '' &&
    attachmentsUploadUrl !== undefined &&
    attachmentsUploadUrl !== ''
  );

  const { validateFile } = useAttachmentValidation();

  // BlockNote 0.44.x creates a "Loading..." placeholder block before awaiting
  // uploadFile (blocknote.js Ie(), ~line 1130) and only calls updateBlock on
  // the success path - it has no try/catch around the await. On rejection,
  // the placeholder is left in the document forever. We remove it ourselves
  // here. removeBlocks is synchronous and safe because BlockNote never
  // touches the block again after the rejected await.
  const removePlaceholder = useCallback((blockId?:string) => {
    const editor = getEditor?.();
    if (!editor || !blockId) return;
    try {
      editor.removeBlocks([blockId]);
    } catch { /* already removed by a collaborator via Yjs */ }
  }, [getEditor]);

  const uploadFile = useCallback(async (file:File, blockId?:string):Promise<string> => {
    try {
      const pluginContext = await window.OpenProject.getPluginContext();

      const validation = await validateFile(file);
      if (!validation.valid) {
        pluginContext.services.notifications.addError(validation.reason);
        removePlaceholder(blockId);
        return '';
      }

      const service = pluginContext.services.attachmentsResourceService;
      const uploadFiles:IUploadFile[] = [{ file }];
      const result = await firstValueFrom(
        service.addAttachments(attachmentsCollectionKey, attachmentsUploadUrl, uploadFiles),
      );

      const href = result?.[0]?._links?.staticDownloadLocation?.href;
      if (!href) {
        throw new Error('Upload returned no download location');
      }
      return href;
    } catch (error) {
      const pluginContext = await window.OpenProject.getPluginContext().catch(() => null);
      pluginContext?.services.notifications.addError(error as never);
      removePlaceholder(blockId);

      // Return '' instead of rethrowing: BlockNote 0.44.x doesn't catch
      // uploadFile rejections, so throwing would surface as Uncaught (in
      // promise). The placeholder is already gone, so the success-path
      // updateBlock that follows our return won't fire anyway.
      return '';
    }
  }, [attachmentsCollectionKey, attachmentsUploadUrl, validateFile, removePlaceholder]);

  if (!enabled) {
    return { enabled };
  }

  return { enabled, uploadFile };
}

export default useBlockNoteAttachments;
