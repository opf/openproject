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

import { HttpClient, HttpEvent } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { share } from 'rxjs/operators';

import { EXTERNAL_REQUEST_HEADER } from 'core-app/features/hal/http/openproject-header-interceptor';

export interface NextcloudUploadConfiguration {
  type:'nextcloud';
  overwrite:boolean;
}

export interface FogStorageUploadConfiguration {
  type:'fog';
  description?:string;
  fileName:string;
  contentType:string;
  fileSize:string;
}

export interface LocalStorageUploadConfiguration {
  type:'local';
  description?:string;
  fileName:string;
}

export type UploadConfiguration =
  NextcloudUploadConfiguration
  |FogStorageUploadConfiguration
  |LocalStorageUploadConfiguration;

export interface FileForUpload extends File {
  config:UploadConfiguration;
}

@Injectable()
export class OpUploadService {
  constructor(private readonly http:HttpClient) {}

  public upload<T>(url:string, files:FileForUpload[]):Observable<HttpEvent<T>>[] {
    return files.map((file) => this.uploadSingle<T>(url, file));
  }

  private uploadSingle<T>(url:string, file:FileForUpload):Observable<HttpEvent<T>> {
    let observable:Observable<HttpEvent<T>>;

    switch (file.config.type) {
      case 'nextcloud':
        observable = this.nextcloudRequest<T>(url, file);
        break;
      case 'local':
        observable = this.localRequest<T>(url, file);
        break;
      default:
        throw new Error(`Cannot create request for type '${file.config.type}'.`);
    }

    return observable.pipe(share());
  }

  private nextcloudRequest<T>(url:string, file:FileForUpload):Observable<HttpEvent<T>> {
    return this.http.request<T>(
      'post',
      url,
      {
        body: this.formData(file),
        headers: { [EXTERNAL_REQUEST_HEADER]: 'true' },
        observe: 'events',
        reportProgress: true,
        responseType: 'json',
      },
    );
  }

  private localRequest<T>(url:string, file:FileForUpload):Observable<HttpEvent<T>> {
    return this.http.request(
      'post',
      url,
      {
        body: this.formData(file),
        observe: 'events',
        withCredentials: true,
        responseType: 'json',
        reportProgress: true,
      },
    );
  }

  private formData(file:FileForUpload):FormData {
    const data = new FormData();

    switch (file.config.type) {
      case 'nextcloud':
        data.append('file', file, file.name);
        data.append('overwrite', String(file.config.overwrite));
        break;
      case 'local':
        data.append('metadata', JSON.stringify({
          description: file.config.description,
          fileName: file.config.fileName,
        }));
        data.append('file', file, file.config.fileName);
        break;
      default:
        console.warn('unknown upload config type');
    }

    return data;
  }
}
