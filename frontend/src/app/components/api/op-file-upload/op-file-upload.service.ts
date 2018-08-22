//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
//++

import {Injectable} from "@angular/core";
import {HttpClient, HttpEvent, HttpEventType, HttpResponse} from "@angular/common/http";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {Observable} from "rxjs";
import {filter, map, share} from "rxjs/operators";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";

export interface UploadFile extends File {
  description?:string;
  customName?:string;
}


export interface UploadBlob extends Blob {
  description?:string;
  customName?:string;
  name?:string;
}

export type UploadHttpEvent = HttpEvent<HalResource>;
export type UploadInProgress = [UploadFile, Observable<UploadHttpEvent>];

export interface UploadResult {
  uploads:UploadInProgress[];
  finished:Promise<any[]>;
}

export interface MappedUploadResult {
  uploads:UploadInProgress[];
  finished:Promise<{ response:any, uploadUrl:string }[]>;
}

@Injectable()
export class OpenProjectFileUploadService {
  constructor(protected http:HttpClient,
              protected halResource:HalResourceService) {
  }

  /**
   * Upload multiple files and return a promise for each uploading file and a single promise for all processed uploads
   * with their accessible URLs returned.
   * @param {string} url
   * @param {UploadFile[]} files
   * @param {string} method
   * @returns {Promise<{response:HalResource; uploadUrl:any}[]>}
   */
  public uploadAndMapResponse(url:string, files:UploadFile[], method:string = 'post') {
    const { uploads, finished } = this.upload(url, files);
    const mapped = finished
      .then((result:HalResource[]) => result.map((el:HalResource) => {
          return { response: el, uploadUrl: el.downloadLocation.href };
      })) as Promise<{ response:HalResource, uploadUrl:string }[]>;

    return { uploads: uploads, finished: mapped } as MappedUploadResult;
  }

  /**
   * Upload multiple files and return a promise for each uploading file and a single promise for all processed uploads
   * Ignore directories.
   */
  public upload(url:string, files:UploadFile[], method:string = 'post'):UploadResult {
    files = _.filter(files, (file:UploadFile) => file.type !== 'directory');
    const uploads:UploadInProgress[] = _.map(files, (file:UploadFile) => this.uploadSingle(url, file, method));

    const finished = this.whenFinished(uploads);
    return {uploads, finished} as UploadResult;
  }

  /**
   * Upload a single file, get an UploadResult observable
   * @param {string} url
   * @param {UploadFile} file
   * @param {string} method
   */
  public uploadSingle(url:string, file:UploadFile|UploadBlob, method:string = 'post', responseType:'text'|'json' = 'json') {
    const formData = new FormData();
    const metadata = {
      description: file.description,
      fileName: file.customName || file.name
    };

    // add the metadata object
    formData.append(
      'metadata',
      JSON.stringify(metadata),
    );

    // Add the file
    formData.append('file', file, metadata.fileName);

    const observable = this
      .http
      .request<HalResource>(
        method,
        url,
        {
          body: formData,
          // Observe the response, not the body
          observe: 'events',
          withCredentials: true,
          responseType: responseType as any,
          // Subscribe to progress events. subscribe() will fire multiple times!
          reportProgress: true
        }
      )
      .pipe(
        share()
      );

    return [file, observable] as UploadInProgress;
  }

  /**
   * Create a promise for all uploaded responses when all uploads are fully uploaded.
   *
   * @param {UploadInProgress[]} uploads
   */
  private whenFinished(uploads:UploadInProgress[]):Promise<HalResource[]> {
    const promises = uploads.map(([_, observable]) => {
      return observable
        .pipe(
          filter((evt) => evt.type === HttpEventType.Response),
          map((evt:HttpResponse<HalResource>) => this.halResource.createHalResource(evt.body))
        )
        .toPromise();
    });

    return Promise.all(promises);
  }
}
