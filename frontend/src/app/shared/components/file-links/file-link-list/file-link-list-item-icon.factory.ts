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
  color:'red'|'blue'|'blue-deep'|'blue-dark'|'turquoise'|'green'|'grey-dark'|'grey'|'orange'
}

const mimeTypeIconMap:{ [mimeType:string]:IFileLinkListItemIcon; } = {
  'image/*': { icon: 'image1', color: 'blue-dark' },
  'text/plain': { icon: 'file-text', color: 'grey-dark' },
  'application/pdf': { icon: 'export-pdf-descr', color: 'red' },
  'application/vnd.oasis.opendocument.text': { icon: 'file-doc', color: 'blue-deep' },
  'application/vnd.oasis.opendocument.spreadsheet': { icon: 'file-sheet', color: 'green' },
  'application/vnd.oasis.opendocument.presentation': { icon: 'file-presentation', color: 'turquoise' },
  'application/x-op-directory': { icon: 'folder', color: 'blue' },
  default: { icon: 'ticket', color: 'grey-dark' },
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
