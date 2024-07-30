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
  icon:'image1'|'movie'|'file-text'|'export-pdf-descr'|'file-doc'|'file-sheet'|'file-presentation'|'folder'|'ticket'
  clazz:'pdf'|'img'|'txt'|'doc'|'sheet'|'presentation'|'form'|'primary'|'mov'|'default'
}

export const fileIconMappings:Record<string, IFileIcon> = {
  'application/pdf': { icon: 'export-pdf-descr', clazz: 'pdf' },

  'image/jpeg': { icon: 'image1', clazz: 'img' },
  'image/png': { icon: 'image1', clazz: 'img' },
  'image/gif': { icon: 'image1', clazz: 'img' },
  'image/svg+xml': { icon: 'image1', clazz: 'img' },
  'image/tiff': { icon: 'image1', clazz: 'img' },
  'image/bmp': { icon: 'image1', clazz: 'img' },
  'image/webp': { icon: 'image1', clazz: 'img' },
  'image/heic': { icon: 'image1', clazz: 'img' },
  'image/heif': { icon: 'image1', clazz: 'img' },
  'image/avif': { icon: 'image1', clazz: 'img' },
  'image/cgm': { icon: 'image1', clazz: 'img' },

  'text/plain': { icon: 'file-text', clazz: 'txt' },
  'text/markdown': { icon: 'file-text', clazz: 'txt' },
  'text/html': { icon: 'file-text', clazz: 'txt' },
  'application/rtf': { icon: 'file-text', clazz: 'txt' },
  'application/xml': { icon: 'file-text', clazz: 'txt' },
  'application/xhtml+xml': { icon: 'file-text', clazz: 'txt' },
  'application/x-tex': { icon: 'file-text', clazz: 'txt' },

  'application/vnd.oasis.opendocument.text': { icon: 'file-doc', clazz: 'doc' },
  'application/vnd.oasis.opendocument.text-template': { icon: 'file-doc', clazz: 'doc' },
  'application/msword': { icon: 'file-doc', clazz: 'doc' },
  'application/vnd.apple.pages': { icon: 'file-doc', clazz: 'doc' },
  'application/vnd.stardivision.writer': { icon: 'file-doc', clazz: 'doc' },
  'application/x-abiword': { icon: 'file-doc', clazz: 'doc' },
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document': { icon: 'file-doc', clazz: 'doc' },
  'font/otf': { icon: 'file-doc', clazz: 'doc' },

  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': { icon: 'file-sheet', clazz: 'sheet' },
  'application/vnd.oasis.opendocument.spreadsheet': { icon: 'file-sheet', clazz: 'sheet' },
  'application/vnd.oasis.opendocument.spreadsheet-template': { icon: 'file-sheet', clazz: 'sheet' },
  'application/vnd.ms-excel': { icon: 'file-sheet', clazz: 'sheet' },
  'application/vnd.stardivision.calc': { icon: 'file-sheet', clazz: 'sheet' },
  'application/vnd.apple.numbers': { icon: 'file-sheet', clazz: 'sheet' },
  'application/x-starcalc': { icon: 'file-sheet', clazz: 'sheet' },
  'application/x-quattro-pro': { icon: 'file-sheet', clazz: 'sheet' },
  'application/csv': { icon: 'file-sheet', clazz: 'sheet' },

  'application/vnd.oasis.opendocument.presentation': { icon: 'file-presentation', clazz: 'presentation' },
  'application/vnd.oasis.opendocument.presentation-template': { icon: 'file-presentation', clazz: 'presentation' },
  'application/vnd.apple.keynote': { icon: 'file-presentation', clazz: 'presentation' },
  'application/vnd.ms-powerpoint': { icon: 'file-presentation', clazz: 'presentation' },
  'application/vnd.openxmlformats-officedocument.presentationml.presentation': {
    icon: 'file-presentation',
    clazz: 'presentation',
  },
  'application/vnd.stardivision.impress': { icon: 'file-presentation', clazz: 'presentation' },
  'application/mathematica': { icon: 'file-presentation', clazz: 'presentation' },

  'video/mp4': { icon: 'movie', clazz: 'mov' },
  'video/x-m4v': { icon: 'movie', clazz: 'mov' },
  'video/avi': { icon: 'movie', clazz: 'mov' },
  'video/quicktime': { icon: 'movie', clazz: 'mov' },
  'video/webm': { icon: 'movie', clazz: 'mov' },
  'video/mpg': { icon: 'movie', clazz: 'mov' },
  'video/x-matroska': { icon: 'movie', clazz: 'mov' },
  'video/mp1s': { icon: 'movie', clazz: 'mov' },
  'video/mp2p': { icon: 'movie', clazz: 'mov' },
  'video/3gpp': { icon: 'movie', clazz: 'mov' },
  'video/3gpp-tt': { icon: 'movie', clazz: 'mov' },
  'video/3gpp-2': { icon: 'movie', clazz: 'mov' },

  'application/x-op-directory': { icon: 'folder', clazz: 'primary' },

  default: { icon: 'ticket', clazz: 'default' },
};

export const storageIconMappings:Record<string, string> = {
  [nextcloud]: 'nextcloud-circle',

  default: 'hosting',
};
