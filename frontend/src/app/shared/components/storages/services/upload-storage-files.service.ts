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

import { IUploadLink } from 'core-app/core/state/storage-files/upload-link.model';
import { IStorageFile } from 'core-app/core/state/storage-files/storage-file.model';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';

@Injectable()
export class UploadStorageFilesService {
  constructor(
    private readonly httpClient:HttpClient,
    private readonly timezoneService:TimezoneService,
  ) {}

  public uploadFile(uploadLink:IUploadLink, file:File):Observable<IStorageFile> {
    const url = new URL(uploadLink._links.destination.href);
    const token = url.username;
    const password = url.password;
    url.username = '';
    url.password = '';

    const headers = {
      Authorization: `Basic ${btoa(`${token}:${password}`)}`,
      'X-External-Request': 'true',
    };

    const method = uploadLink._links.destination.method;
    return this.httpClient
      .request(method, url.toString(), { body: file, headers })
      .pipe(
        switchMap(() => this.httpClient.request(
          'propfind',
          url.toString(),
          {
            body: this.propfindBody,
            headers,
            responseType: 'text',
          },
        )),
        map((xml) => this.parseXmlResponse(xml)),
      );
  }

  private parseXmlResponse(xml:string):IStorageFile {
    const error = new Error(`Invalid response for uploaded file: ${xml}`);

    const id = /<oc:fileid>(.*)<\/oc:fileid>/.exec(xml)?.pop();
    if (!id) { throw error; }

    const mimeType = /<d:getcontenttype>(.*)<\/d:getcontenttype>/.exec(xml)?.pop();
    if (!mimeType) { throw error; }

    const size = /<oc:size>(.*)<\/oc:size>/.exec(xml)?.pop();
    if (!size) { throw error; }

    const href = /<d:href>(.*)<\/d:href>/.exec(xml)?.pop();
    const parts = href?.split('/');
    if (!parts || parts.length < 1) { throw error; }

    const name = parts.pop();
    if (!name) { throw error; }

    const location = `/${parts.slice(parts.indexOf('webdav') + 1).join('/')}`;

    const date = /<d:getlastmodified>(.*)<\/d:getlastmodified>/.exec(xml)?.pop();
    if (!date) { throw error; }
    const createdAt = this.timezoneService.parseDatetime(date).toISOString();
    const lastModifiedAt = createdAt;

    const creator = /<oc:owner-display-name>(.*)<\/oc:owner-display-name>/.exec(xml)?.pop();
    if (!creator) { throw error; }

    return {
      id,
      name: decodeURIComponent(name),
      location,
      mimeType,
      size: parseInt(size, 10),
      createdAt,
      createdByName: creator,
      lastModifiedAt,
      lastModifiedByName: creator,
    };
  }

  private get propfindBody() {
    return '<?xml version="1.0"?>\n'
      + '<d:propfind xmlns:d="DAV:" xmlns:oc="http://owncloud.org/ns" xmlns:nc="http://nextcloud.org/ns">\n'
      + '  <d:prop>\n'
      + '    <oc:fileid />\n'
      + '    <d:getlastmodified />\n'
      + '    <d:getcontenttype />\n'
      + '    <oc:size />\n'
      + '    <oc:owner-display-name />\n'
      + '  </d:prop>\n'
      + '</d:propfind>';
  }
}
