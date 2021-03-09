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

/*jshint expr: true*/

import { CurrentProjectService } from "core-components/projects/current-project.service";
import { GlobalSearchService } from "core-app/modules/global_search/services/global-search.service";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { TestBed, waitForAsync } from "@angular/core/testing";
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { States } from "core-components/states.service";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";

describe('Global search service', function() {
  let service:GlobalSearchService;
  let CurrentProject:CurrentProjectService;
  let CurrentProjectSpy;

  beforeEach(waitForAsync(() => {
    // noinspection JSIgnoredPromiseFromCall
    TestBed.configureTestingModule({
      providers: [
        I18nService,
        PathHelperService,
        States,
        APIV3Service,
        CurrentProjectService,
        GlobalSearchService,
      ]
    })
      .compileComponents()
      .then(() => {
        CurrentProject = TestBed.get(CurrentProjectService);
        service = TestBed.get(GlobalSearchService);
      });
  }));

  describe('outside a project', () => {
    beforeEach(() => {
      CurrentProjectSpy = spyOnProperty(CurrentProject, 'path', 'get').and.returnValue(null);
    });

    it('searchPath returns a correct path', () => {
      service.searchTerm = 'hello';
      expect(service.searchPath()).toEqual('/search?q=hello&work_packages=1');
    });

    it('searchPath encodes the search term', () => {
      service.searchTerm = '<%';
      expect(service.searchPath()).toEqual('/search?q=%3C%25&work_packages=1');
    });

    it('searchPath entails the current tab', () => {
      service.currentTab = 'wiki_pages';
      expect(service.searchPath()).toEqual('/search?q=&wiki_pages=1');
    });

    it('when currentTab is "all" searchPath does not add it as a params key', () => {
      service.currentTab = 'all';
      expect(service.searchPath()).toEqual('/search?q=');
    });
  });

  describe('within a project', () => {
    beforeEach(() => {
      CurrentProjectSpy = spyOnProperty(CurrentProject, 'path', 'get')
        .and
        .returnValue('/projects/myproject');
    });

    it('returns correct path containing the project', () => {
      expect(service.searchPath()).toEqual('/projects/myproject/search?q=&work_packages=1');
    });

    it('returns correct path containing the project scope', () => {
      service.projectScope = 'current_project';
      expect(service.searchPath()).toEqual('/projects/myproject/search?q=&work_packages=1&scope=current_project');
    });
  });
});
