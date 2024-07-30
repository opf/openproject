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

import {
  fileIconMappings,
  IFileIcon,
  storageIconMappings,
} from 'core-app/shared/components/storages/icons.mapping';
import { IHalResourceLink } from 'core-app/core/state/hal-resource';
import { IFileLinkOriginData } from 'core-app/core/state/file-links/file-link.model';
import { nextcloud, oneDrive } from 'core-app/shared/components/storages/storages-constants.const';

export function isDirectory(originData:IFileLinkOriginData):boolean {
  return originData.mimeType === 'application/x-op-directory';
}

export function getIconForMimeType(mimeType?:string):IFileIcon {
  if (mimeType && fileIconMappings[mimeType]) {
    return fileIconMappings[mimeType];
  }

  return fileIconMappings.default;
}

export function getIconForStorageType(storageType?:string):string {
  if (storageType && storageIconMappings[storageType]) {
    return storageIconMappings[storageType];
  }

  return storageIconMappings.default;
}

export function makeFilesCollectionLink(storageLink:IHalResourceLink, location:string):IHalResourceLink {
  const query = location !== '/' ? `?parent=${location}` : '';

  return {
    href: `${storageLink.href}/files${query}`,
    title: 'Storage files',
  };
}

const storageTypeMap:Record<string, string> = {
  [nextcloud]: 'js.storages.types.nextcloud',
  [oneDrive]: 'js.storages.types.one_drive',
  default: 'js.storages.types.default',
};

export function storageLocaleString(storageTypeUrn:string) {
  return storageTypeMap[storageTypeUrn] || storageTypeMap.default;
}
