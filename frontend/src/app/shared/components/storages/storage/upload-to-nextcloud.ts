// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2023 the OpenProject GmbH
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

import { Observable } from 'rxjs';
import { HttpEvent } from '@angular/common/http';

import { FileForUpload, OpUploadService } from 'core-app/core/upload/upload.service';
import { IUploadLink } from 'core-app/core/state/storage-files/upload-link.model';

export interface FileUploadResponse {
  file_name:string;
  file_id:string;
}

export default function uploadToNextcloud(
  uploadService:OpUploadService,
  uploadLink:IUploadLink,
  file:File,
):Observable<HttpEvent<FileUploadResponse>> {
  const { href } = uploadLink._links.destination;

  const upload = file as FileForUpload;
  upload.config = { overwrite: false, type: 'nextcloud' };

  return uploadService.upload<FileUploadResponse>(href, [upload])[0];
}
