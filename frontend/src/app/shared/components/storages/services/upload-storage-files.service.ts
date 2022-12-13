// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2022 the OpenProject GmbH
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

import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map, switchMap } from 'rxjs/operators';

@Injectable()
export class UploadStorageFilesService {
  private token = 'JXSQ7knPCkgCWtp';

  private password = 'ad84c32b-b4bf-4b6e-bea2-4b2204d1f66e';

  constructor(
    private readonly httpClient:HttpClient,
  ) {}

  public uploadFile(file:File):Observable<string> {
    const headers = {
      Authorization: `Basic ${btoa(`${this.token}:${this.password}`)}`,
      'X-External-Request': 'true',
    };

    const body = '<?xml version="1.0"?>\n'
      + '<d:propfind xmlns:d="DAV:" xmlns:oc="http://owncloud.org/ns">\n'
      + '  <d:prop>\n'
      + '        <oc:fileid />\n'
      + '  </d:prop>\n'
      + '</d:propfind>';

    const url = `https://nextcloud.local/public.php/webdav/${(file.name)}`;
    return this.httpClient
      .put(url, file, { headers })
      .pipe(
        switchMap(() => this.httpClient.request('propfind', url, { body, headers, responseType: 'text' })),
        map((xml) => {
          const fileId = /<oc:fileid>(.*)<\/oc:fileid>/.exec(xml)?.pop();
          if (!fileId) { throw new Error('no file id found'); }
          return fileId;
        }),
      );
  }
}
