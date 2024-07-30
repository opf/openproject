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

import { Observable } from 'rxjs';
import { share } from 'rxjs/operators';
import { HttpClient, HttpEvent } from '@angular/common/http';

import { IUploadFile, OpUploadService } from 'core-app/core/upload/upload.service';

export interface AttachmentUploadFile extends IUploadFile {
  description?:string;
}

export class LocalUploadService extends OpUploadService {
  constructor(
    private readonly http:HttpClient,
  ) {
    super();
  }

  public upload<T>(
    href:string,
    uploadFiles:AttachmentUploadFile[],
  ):Observable<HttpEvent<T>>[] {
    return uploadFiles.map((file) => this.uploadSingle(href, file));
  }

  private uploadSingle<T>(href:string, uploadFile:AttachmentUploadFile):Observable<HttpEvent<T>> {
    const body = new FormData();
    const metadata = {
      description: uploadFile.description,
      fileName: uploadFile.file.name,
    };

    body.append('metadata', JSON.stringify(metadata));
    body.append('file', uploadFile.file, metadata.fileName);

    return this.http.request<T>(
      'post',
      href,
      {
        body,
        observe: 'events',
        withCredentials: true,
        responseType: 'json',
        reportProgress: true,
      },
    ).pipe(share());
  }
}
