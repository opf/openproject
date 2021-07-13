// -- copyright
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

import { AfterViewInit, Component, ViewEncapsulation } from '@angular/core';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import * as SwaggerUI from 'swagger-ui';

@Component({
  selector: 'op-api-docs',
  styleUrls: ['./swagger-ui.component.sass'],
  templateUrl: './swagger-ui.component.html',
  encapsulation: ViewEncapsulation.None,
})
export class SwaggerUIComponent implements AfterViewInit {
  constructor(private pathHelperService:PathHelperService) {
  }

  ngAfterViewInit() {
    SwaggerUI({
      dom_id: '#swagger',
      url: this.pathHelperService.api.v3.openApiSpecPath,
      filter: true,
      requestInterceptor: (req) => {
        if (!req.loadSpec) {
          // required to make session-based authentication work for POST requests with APIv3
          req.headers['X-Requested-With'] = 'XMLHttpRequest';
        }
        return req;
      },
    });
  }
}
