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

import { TestBed } from '@angular/core/testing';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { CurrentProjectService } from './current-project.service';

describe('currentProject service', () => {
  let element:HTMLMetaElement;
  let currentProject:CurrentProjectService;

  const apiV3Stub:any = {
    projects: {
      id: (id:string) => ({ toString: () => `/api/v3/projects/${id}` }),
    },
  };

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        CurrentProjectService,
        PathHelperService,
        // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
        { provide: ApiV3Service, useValue: apiV3Stub },
      ],
    });
    currentProject = TestBed.inject(CurrentProjectService);
  });

  describe('with no meta present', () => {
    it('returns null values', () => {
      expect(currentProject.id).toBeNull();
      expect(currentProject.identifier).toBeNull();
      expect(currentProject.name).toBeNull();
      expect(currentProject.apiv3Path).toBeNull();
      expect(currentProject.inProjectContext).toBeFalsy();
    });
  });

  describe('with a meta value present', () => {
    beforeEach(() => {
      element = document.createElement('meta');
      element.setAttribute('name', 'current_project');
      element.dataset.projectName = 'Foo 1234';
      element.dataset.projectId = '1';
      element.dataset.projectIdentifier = 'foobar';
      document.head.appendChild(element);
      currentProject.detect();
    });

    afterEach((() => {
      element.remove();
    }));

    it('returns correct values', () => {
      expect(currentProject.inProjectContext).toBeTruthy();
      expect(currentProject.id).toEqual('1');
      expect(currentProject.name).toEqual('Foo 1234');
      expect(currentProject.identifier).toEqual('foobar');
      expect(currentProject.apiv3Path).toEqual('/api/v3/projects/1');
    });
  });
});
