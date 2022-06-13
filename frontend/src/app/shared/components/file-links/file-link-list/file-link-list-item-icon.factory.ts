// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2022 the OpenProject GmbH
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

export interface IFileLinkListItemIcon {
  icon:'image1'|'movie'|'file-text'|'export-pdf-descr'|'file-doc'|'file-sheet'|'file-presentation'|'folder'|'ticket'
  clazz:'pdf'|'img'|'txt'|'doc'|'sheet'|'presentation'|'form'|'dir'|'default'
}

const mimeTypeIconMap:{ [mimeType:string]:IFileLinkListItemIcon; } = {
  'image/*': { icon: 'image1', clazz: 'img' },
  'text/plain': { icon: 'file-text', clazz: 'txt' },
  'application/pdf': { icon: 'export-pdf-descr', clazz: 'pdf' },
  'application/vnd.oasis.opendocument.text': { icon: 'file-doc', clazz: 'doc' },
  'application/vnd.oasis.opendocument.spreadsheet': { icon: 'file-sheet', clazz: 'sheet' },
  'application/vnd.oasis.opendocument.presentation': { icon: 'file-presentation', clazz: 'presentation' },
  'application/x-op-directory': { icon: 'folder', clazz: 'dir' },
  default: { icon: 'ticket', clazz: 'default' },
};

export function getIconForMimeType(mimeType?:string):IFileLinkListItemIcon {
  if (mimeType?.startsWith('image/')) {
    return mimeTypeIconMap['image/*'];
  }

  if (mimeType && mimeTypeIconMap[mimeType]) {
    return mimeTypeIconMap[mimeType];
  }

  return mimeTypeIconMap.default;
}
