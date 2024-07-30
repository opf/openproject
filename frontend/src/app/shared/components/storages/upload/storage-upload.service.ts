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
import { ID } from '@datorama/akita';
import { Injectable } from '@angular/core';
import { HttpClient, HttpEvent } from '@angular/common/http';

import { IUploadFile, OpUploadService } from 'core-app/core/upload/upload.service';
import { IUploadStrategy } from 'core-app/shared/components/storages/upload/upload-strategy';
import { NextcloudUploadStrategy } from 'core-app/shared/components/storages/upload/nextcloud-upload.strategy';
import { nextcloud, oneDrive } from 'core-app/shared/components/storages/storages-constants.const';
import { OneDriveUploadStrategy } from 'core-app/shared/components/storages/upload/one-drive-upload.strategy';

export interface IStorageFileUploadResponse {
  id:ID;
  name:string;
  mimeType:string;
  size:number;
}

@Injectable()
export class StorageUploadService extends OpUploadService {
  private uploadStrategy:IUploadStrategy;

  constructor(
    private readonly http:HttpClient,
  ) {
    super();
  }

  public upload<T>(
    href:string,
    uploadFiles:IUploadFile[],
  ):Observable<HttpEvent<T>>[] {
    if (!this.uploadStrategy) {
      throw new Error('missing strategy');
    }

    return this.uploadStrategy.execute(href, uploadFiles);
  }

  public setUploadStrategy(storageType:string):void {
    switch (storageType) {
      case nextcloud:
        this.uploadStrategy = new NextcloudUploadStrategy(this.http);
        break;
      case oneDrive:
        this.uploadStrategy = new OneDriveUploadStrategy(this.http);
        break;
      default:
        throw new Error('unknown storage type');
    }
  }
}
