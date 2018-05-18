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

import {opApiModule} from '../../../angular-modules';
import IQService = angular.IQService;
import IPromise = angular.IPromise;

export interface UploadFile extends File {
  description?:string;
  customName?:string;
}

export interface UploadResult {
  uploads:IPromise<any>[];
  finished:IPromise<any>;
}

export class OpenProjectFileUploadService {
  constructor(protected $q:IQService,
              protected Upload:any) {
  }

  /**
   * Upload multiple files using `ngFileUpload` and return a single promise.
   * Ignore directories.
   */
  public upload(url:string, files:UploadFile[]):UploadResult {
    files = _.filter(files, (file:UploadFile) => file.type !== 'directory');
    const uploads = _.map(files, (file:UploadFile) => {
      const metadata = {
        description: file.description,
        fileName: file.customName || file.name
      };

      // need to wrap the metadata into a JSON ourselves as ngFileUpload
      // will otherwise break up the metadata into individual parts
      const data =  {
        metadata: JSON.stringify(metadata),
        file
      };

      return this.Upload.upload({data, url});
    });
    const finished = this.$q.all(uploads);
    return {uploads, finished};
  }
}

opApiModule.service('opFileUpload', OpenProjectFileUploadService);
