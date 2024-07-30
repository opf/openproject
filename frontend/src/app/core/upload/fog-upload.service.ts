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

import { getType } from 'mime';
import { Observable, of } from 'rxjs';
import { map, share, switchMap } from 'rxjs/operators';
import { HttpClient, HttpEvent, HttpEventType } from '@angular/common/http';

import { OpUploadService } from 'core-app/core/upload/upload.service';
import { AttachmentUploadFile } from 'core-app/core/upload/local-upload.service';
import { IAttachmentUpload } from 'core-app/core/state/attachments/attachment.model';
import { EXTERNAL_REQUEST_HEADER } from 'core-app/features/hal/http/openproject-header-interceptor';

interface PrepareUploadData {
  upload:{ href:string, method:string, form:FormData, };
  finishUrl:string;
}

export class FogUploadService extends OpUploadService {
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
    return this.prepareUpload(href, uploadFile)
      .pipe(
        switchMap((data) =>
          this.performUpload(data.upload.href, data.upload.method, data.upload.form)
            .pipe(
              switchMap(this.finishUpload<T>(data.finishUrl)),
            )),
        share(),
      );
  }

  private prepareUpload(href:string, uploadFile:AttachmentUploadFile):Observable<PrepareUploadData> {
    const fileName = uploadFile.file.name;
    const contentType = (uploadFile.file.type || (fileName && getType(fileName)) || '' as string);
    const metadata = {
      fileName,
      contentType,
      description: uploadFile.description,
      fileSize: uploadFile.file.size,
    };

    const body = new FormData();
    body.append('metadata', JSON.stringify(metadata));

    return this.http.request<IAttachmentUpload>(
      'post',
      href,
      {
        body,
        withCredentials: true,
        responseType: 'json',
      },
    ).pipe(
      map((response) => {
        const form = new FormData();
        const formFields = response._links.addAttachment.form_fields;
        Object.entries(formFields).forEach(([key, value]) => {
          form.append(key, value as string);
        });
        form.append('file', uploadFile.file, uploadFile.file.name);

        return {
          upload: {
            href: response._links.addAttachment.href,
            method: response._links.addAttachment.method,
            form,
          },
          finishUrl: response._links.completeUpload.href,
        };
      }),
    );
  }

  private performUpload(href:string, method:string, body:FormData):Observable<HttpEvent<string>> {
    return this.http.request(
      method,
      href,
      {
        body,
        observe: 'events',
        headers: { [EXTERNAL_REQUEST_HEADER]: 'true' },
        responseType: 'text',
        reportProgress: true,
      },
    );
  }

  private finishUpload<T>(href:string):(event:HttpEvent<string>) => Observable<HttpEvent<T>> {
    return (ev) => {
      if (ev.type === HttpEventType.Response) {
        return this.http.get<T>(href, { observe: 'response' });
      }

      return of(ev);
    };
  }
}
