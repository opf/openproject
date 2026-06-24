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

import { useCallback } from 'react';

export type AttachmentValidationResult =
  | { valid:true }
  | { valid:false; reason:string };

export function useAttachmentValidation() {
  const validateFile = useCallback(async (file:File):Promise<AttachmentValidationResult> => {
    const pluginContext = await window.OpenProject.getPluginContext();
    const whitelist = pluginContext.services.configurationService.attachmentWhitelist;

    if (!whitelist || whitelist.length === 0) {
      return { valid: true };
    }

    // Empty file.type means the browser couldn't infer the MIME from the
    // extension (e.g. .xyz). Defer to the backend in that case - it does
    // real magic-byte detection that we can't replicate cheaply on the client.
    if (!file.type) {
      return { valid: true };
    }

    const ext = file.name.split('.').pop()?.toLowerCase();
    const allowed = whitelist.some((entry) =>
      entry.startsWith('*.')
        ? entry.slice(2).toLowerCase() === ext
        : entry === file.type,
    );

    if (allowed) {
      return { valid: true };
    }

    return {
      valid: false,
      reason: window.I18n.t(
        'js.error_attachment_type_not_allowed',
        { value: file.type },
      ),
    };
  }, []);

  return { validateFile };
}

export default useAttachmentValidation;
