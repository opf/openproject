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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { http, HttpResponse } from 'msw';

export const handlers = [
  // Dynamic handler supporting multiple test cases for different status codes controlled via document ID.
  // This also ensures that the Authorization header and Content-type are sent as well.
  http.get<{ protocol: string, host: string, id: string }>(':protocol://:host/api/v3/documents/:id', (request) => {
    if (!request.request.headers.get('Authorization') || request.params.id == '401') {
      return HttpResponse.json({ error: 'unauthorized' }, { status: 401 });
    }

    if (request.request.headers.get('Content-type') != 'application/json') {
      return HttpResponse.json({ error: 'unexpected content type' }, { status: 415 });
    }

    if (request.params.id == '404') {
      return HttpResponse.json({ error: 'not found' }, { status: 404 });
    }

    return HttpResponse.json({
      id: request.params.id,
      title: 'Some existing document',
      __echo: {
        url: request.request.url,
        xForwardedProtoHeader: request.request.headers.get("X-Forwarded-Proto")
      }
    });
  }),
];
