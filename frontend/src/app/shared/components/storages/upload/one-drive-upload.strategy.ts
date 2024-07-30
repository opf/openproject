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
import { map, share } from 'rxjs/operators';
import { HttpClient, HttpEvent } from '@angular/common/http';

import { IUploadFile } from 'core-app/core/upload/upload.service';
import { EXTERNAL_REQUEST_HEADER } from 'core-app/features/hal/http/openproject-header-interceptor';
import { IUploadStrategy } from 'core-app/shared/components/storages/upload/upload-strategy';
import convertHttpEvent from 'core-app/core/upload/convert-http-event';

export interface OneDriveFileUploadResponse {
  id:string;
  name:string;
  file:{ mimeType:string };
  size:number;
}

export class OneDriveUploadStrategy implements IUploadStrategy {
  constructor(private readonly http:HttpClient) { }

  public execute<T>(
    href:string,
    uploadFiles:IUploadFile[],
  ):Observable<HttpEvent<T>>[] {
    return uploadFiles.map((file) => this.uploadSingle(href, file));
  }

  private uploadSingle<T>(href:string, uploadFile:IUploadFile):Observable<HttpEvent<T>> {
    const contentRangeHeader = `bytes 0-${uploadFile.file.size - 1}/${uploadFile.file.size}`;

    return this.http.request<OneDriveFileUploadResponse>(
      'put',
      href,
      {
        body: uploadFile.file,
        headers: {
          [EXTERNAL_REQUEST_HEADER]: 'true',
          'Content-Range': contentRangeHeader,
        },
        observe: 'events',
        reportProgress: true,
        responseType: 'json',
      },
    ).pipe(
      share(),
      map((event) =>
        convertHttpEvent(event, (responseBody) => ({
          id: responseBody.id,
          name: responseBody.name,
          size: responseBody.size,
          mimeType: responseBody.file.mimeType,
        } as T))),
    );
  }
}
