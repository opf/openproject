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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { nextcloud } from 'core-app/shared/components/storages/storages-constants.const';

export interface IFileIcon {
  icon:'file'|'file-directory-fill'|'file-media'|'op-file-csv'|'op-file-doc'|'op-file-presentation'|'op-file-sheet'|'op-file-text'|'op-pdf'|'server'
  clazz:'pdf'|'img'|'txt'|'doc'|'sheet'|'presentation'|'form'|'primary'|'mov'|'default'
}

export const fileIconMappings:Record<string, IFileIcon> = {
  'application/pdf': { icon: 'op-pdf', clazz: 'pdf' },

  'image/jpeg': { icon: 'file-media', clazz: 'img' },
  'image/png': { icon: 'file-media', clazz: 'img' },
  'image/gif': { icon: 'file-media', clazz: 'img' },
  'image/svg+xml': { icon: 'file-media', clazz: 'img' },
  'image/tiff': { icon: 'file-media', clazz: 'img' },
  'image/bmp': { icon: 'file-media', clazz: 'img' },
  'image/webp': { icon: 'file-media', clazz: 'img' },
  'image/heic': { icon: 'file-media', clazz: 'img' },
  'image/heif': { icon: 'file-media', clazz: 'img' },
  'image/avif': { icon: 'file-media', clazz: 'img' },
  'image/cgm': { icon: 'file-media', clazz: 'img' },

  'text/plain': { icon: 'op-file-text', clazz: 'txt' },
  'text/markdown': { icon: 'op-file-text', clazz: 'txt' },
  'text/html': { icon: 'op-file-text', clazz: 'txt' },
  'application/rtf': { icon: 'op-file-text', clazz: 'txt' },
  'application/xml': { icon: 'op-file-text', clazz: 'txt' },
  'application/xhtml+xml': { icon: 'op-file-text', clazz: 'txt' },
  'application/x-tex': { icon: 'op-file-text', clazz: 'txt' },

  'application/vnd.oasis.opendocument.text': { icon: 'op-file-doc', clazz: 'doc' },
  'application/vnd.oasis.opendocument.text-template': { icon: 'op-file-doc', clazz: 'doc' },
  'application/msword': { icon: 'op-file-doc', clazz: 'doc' },
  'application/vnd.apple.pages': { icon: 'op-file-doc', clazz: 'doc' },
  'application/vnd.stardivision.writer': { icon: 'op-file-doc', clazz: 'doc' },
  'application/x-abiword': { icon: 'op-file-doc', clazz: 'doc' },
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document': { icon: 'op-file-doc', clazz: 'doc' },
  'font/otf': { icon: 'op-file-doc', clazz: 'doc' },

  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': { icon: 'op-file-sheet', clazz: 'sheet' },
  'application/vnd.oasis.opendocument.spreadsheet': { icon: 'op-file-sheet', clazz: 'sheet' },
  'application/vnd.oasis.opendocument.spreadsheet-template': { icon: 'op-file-sheet', clazz: 'sheet' },
  'application/vnd.ms-excel': { icon: 'op-file-sheet', clazz: 'sheet' },
  'application/vnd.stardivision.calc': { icon: 'op-file-sheet', clazz: 'sheet' },
  'application/vnd.apple.numbers': { icon: 'op-file-sheet', clazz: 'sheet' },
  'application/x-starcalc': { icon: 'op-file-sheet', clazz: 'sheet' },
  'application/x-quattro-pro': { icon: 'op-file-sheet', clazz: 'sheet' },

  'application/csv': { icon: 'op-file-csv', clazz: 'sheet' },

  'application/vnd.oasis.opendocument.presentation': { icon: 'op-file-presentation', clazz: 'presentation' },
  'application/vnd.oasis.opendocument.presentation-template': { icon: 'op-file-presentation', clazz: 'presentation' },
  'application/vnd.apple.keynote': { icon: 'op-file-presentation', clazz: 'presentation' },
  'application/vnd.ms-powerpoint': { icon: 'op-file-presentation', clazz: 'presentation' },
  'application/vnd.openxmlformats-officedocument.presentationml.presentation': {
    icon: 'op-file-presentation',
    clazz: 'presentation',
  },
  'application/vnd.stardivision.impress': { icon: 'op-file-presentation', clazz: 'presentation' },
  'application/mathematica': { icon: 'op-file-presentation', clazz: 'presentation' },

  'video/mp4': { icon: 'file-media', clazz: 'mov' },
  'video/x-m4v': { icon: 'file-media', clazz: 'mov' },
  'video/avi': { icon: 'file-media', clazz: 'mov' },
  'video/quicktime': { icon: 'file-media', clazz: 'mov' },
  'video/webm': { icon: 'file-media', clazz: 'mov' },
  'video/mpg': { icon: 'file-media', clazz: 'mov' },
  'video/x-matroska': { icon: 'file-media', clazz: 'mov' },
  'video/mp1s': { icon: 'file-media', clazz: 'mov' },
  'video/mp2p': { icon: 'file-media', clazz: 'mov' },
  'video/3gpp': { icon: 'file-media', clazz: 'mov' },
  'video/3gpp-tt': { icon: 'file-media', clazz: 'mov' },
  'video/3gpp-2': { icon: 'file-media', clazz: 'mov' },

  'application/x-op-directory': { icon: 'file-directory-fill', clazz: 'primary' },
  'application/x-op-drive': { icon: 'server', clazz: 'primary' },

  default: { icon: 'file', clazz: 'default' },
};

export const storageIconMappings:Record<string, string> = {
  [nextcloud]: 'nextcloud-circle',

  default: 'cloud',
};
