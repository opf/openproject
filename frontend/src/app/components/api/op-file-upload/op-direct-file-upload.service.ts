//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import { Injectable } from "@angular/core";
import { HttpEvent, HttpResponse } from "@angular/common/http";
import { HalResource } from "core-app/modules/hal/resources/hal-resource";
import { from, Observable, of } from "rxjs";
import { share, switchMap } from "rxjs/operators";
import { OpenProjectFileUploadService, UploadBlob, UploadFile, UploadInProgress } from './op-file-upload.service';

interface PrepareUploadResult {
  url:string;
  form:FormData;
  response:any;
}

@Injectable()
export class OpenProjectDirectFileUploadService extends OpenProjectFileUploadService {
  /**
   * Upload a single file, get an UploadResult observable
   * @param {string} url
   * @param {UploadFile} file
   * @param {string} method
   */
  public uploadSingle(url:string, file:UploadFile|UploadBlob, method = 'post', responseType:'text'|'json' = 'text') {
    const observable = from(this.getDirectUploadFormFrom(url, file))
      .pipe(
        switchMap(this.uploadToExternal(file, method, responseType)),
        share()
      );

    return [file, observable] as UploadInProgress;
  }

  private uploadToExternal(file:UploadFile|UploadBlob, method:string, responseType:string):(result:PrepareUploadResult) => Observable<HttpEvent<unknown>> {
    return result => {
      result.form.append('file', file, file.customName || file.name);

      return this
        .http
        .request<HalResource>(
          method,
          result.url,
          {
            body: result.form,
            // Observe the response, not the body
            observe: 'events',
            // This is important as the CORS policy for the bucket is * and you can't use credentals then,
            // besides we don't need them here anyway.
            withCredentials: false,
            responseType: responseType as any,
            // Subscribe to progress events. subscribe() will fire multiple times!
            reportProgress: true
          }
        )
        .pipe(switchMap(this.finishUpload(result)));
    };
  }

  private finishUpload(result:PrepareUploadResult):(result:HttpEvent<unknown>) => Observable<HttpEvent<unknown>> {
    return event => {
      if (event instanceof HttpResponse) {
        return this
          .http
          .get(
            result.response._links.completeUpload.href,
            {
              observe: 'response'
            }
          );
      }

      // Return as new observable due to switchMap
      return of(event);
    };
  }

  public getDirectUploadFormFrom(url:string, file:UploadFile|UploadBlob):Promise<PrepareUploadResult> {
    const formData = new FormData();
    const metadata = {
      description: file.description,
      fileName: file.customName || file.name,
      fileSize: file.size,
      contentType: file.type
    };

    /*
     * @TODO We could calculate the MD5 hash here too and pass that.
     * The MD5 hash can be used as the `content-md5` option during the upload to S3 for instance.
     * This way S3 can verify the integrity of the file which we currently don't do.
     */

    // add the metadata object
    formData.append(
      'metadata',
      JSON.stringify(metadata),
    );

    const result = this
      .http
      .request<HalResource>(
        "post",
        url,
        {
          body: formData,
          withCredentials: true,
          responseType: "json" as any
        }
      )
      .toPromise()
      .then((res) => {
        const form = new FormData();

        _.each(res._links.addAttachment.form_fields, (value, key) => {
          form.append(key, value);
        });

        return { url: res._links.addAttachment.href, form: form, response: res };
      });

    return result;
  }
}
