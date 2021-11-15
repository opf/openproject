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
// See COPYRIGHT and LICENSE files for more details.
//++

/* jshint expr: true */

import { getTestBed, TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { States } from 'core-app/core/states/states.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { CurrentUserService } from './current-user.service';
import { CurrentUser, CurrentUserStore } from './current-user.store';
import { CurrentUserQuery } from './current-user.query';

const globalCapability = {
  _type: 'Capability',
  id: 'placeholder_users/read/g-3',
  _links: {
    self: {
      href: '/api/v3/capabilities/placeholder_users/read/g-3',
    },
    action: {
      href: '/api/v3/actions/placeholder_users/read',
    },
    context: {
      href: '/api/v3/capabilities/contexts/global',
      title: 'Global',
    },
    principal: {
      href: '/api/v3/users/1',
      title: 'OpenProject Admin',
    },
  },
};

const projectCapabilityp63Update = {
  _type: 'Capability',
  id: 'memberships/update/p6-3',
  _links: {
    self: {
      href: '/api/v3/capabilities/memberships/update/p6-3',
    },
    action: {
      href: '/api/v3/actions/memberships/update',
    },
    context: {
      href: '/api/v3/projects/6',
      title: 'Project 6',
    },
    principal: {
      href: '/api/v3/users/1',
      title: 'OpenProject Admin',
    },
  },
};

const projectCapabilityp63Read = {
  _type: 'Capability',
  id: 'memberships/read/p6-3',
  _links: {
    self: {
      href: '/api/v3/capabilities/memberships/read/p6-3',
    },
    action: {
      href: '/api/v3/actions/memberships/read',
    },
    context: {
      href: '/api/v3/projects/6',
      title: 'Project 6',
    },
    principal: {
      href: '/api/v3/users/1',
      title: 'OpenProject Admin',
    },
  },
};

const projectCapabilityp53Update = {
  _type: 'Capability',
  id: 'memberships/update/p5-3',
  _links: {
    self: {
      href: '/api/v3/capabilities/memberships/update/p5-3',
    },
    action: {
      href: '/api/v3/actions/memberships/update',
    },
    context: {
      href: '/api/v3/projects/5',
      title: 'Project 5',
    },
    principal: {
      href: '/api/v3/users/1',
      title: 'OpenProject Admin',
    },
  },
};

describe('CurrentUserService', () => {
  let injector:TestBed;
  let currentUserService:CurrentUserService;
  let httpMock:HttpTestingController;

  const compile = (user:CurrentUser) => {
    const ConfigurationServiceStub = {};

    TestBed.configureTestingModule({
      imports: [
        HttpClientTestingModule,
      ],
      providers: [
        HalResourceService,
        CurrentUserStore,
        CurrentUserQuery,
        { provide: ConfigurationService, useValue: ConfigurationServiceStub },
        { provide: States, useValue: new States() },
      ],
    });

    injector = getTestBed();
    currentUserService = TestBed.inject(CurrentUserService);
    httpMock = TestBed.inject(HttpTestingController);

    currentUserService.setUser(user);
  };

  const mockRequest = () => {
    httpMock
      .match((req) => req.url.includes('/api/v3/capabilities'))
      .forEach((req) => {
        expect(req.request.method).toBe('GET');
        req.flush({
          _type: 'Collection',
          count: 4,
          total: 4,
          pageSize: 1000,
          offset: 1,
          _embedded: {
            elements: [
              globalCapability,
              projectCapabilityp63Update,
              projectCapabilityp63Read,
              projectCapabilityp53Update,
            ],
          },
        });
      });
  };

  afterEach(() => {
    httpMock.verify();
  });

  describe('When not logged in', () => {
    beforeEach(() => compile({ id: null, name: null, mail: null }));

    it('Should have no capabilities', () => {
      currentUserService.capabilities$.subscribe((caps) => {
        console.log(caps);
        expect(caps.length).toEqual(0);
      });

      mockRequest();
    });

    it('Should not think it is', () => {
      currentUserService.isLoggedIn$.subscribe((loggedIn) => {
        expect(loggedIn).toEqual(false);
      });

      mockRequest();
    });
  });

  describe('When logged in', () => {
    beforeEach(() => compile({ id: '1', name: 'Admin', mail: 'admin@example.com' }));

    it('Should know it is', () => {
      currentUserService.isLoggedIn$.subscribe((loggedIn) => {
        expect(loggedIn).toEqual(true);
      });

      mockRequest();
    });

    it('Should have all capabilities', () => {
      currentUserService.capabilities$.subscribe((caps) => {
        expect(caps.length).toEqual(4);
      });

      mockRequest();
    });

    it('Should filter by context', () => {
      currentUserService.capabilitiesForContext$('global').subscribe((caps) => {
        expect(caps.length).toEqual(1);
      });
      currentUserService.capabilitiesForContext$('6').subscribe((caps) => {
        expect(caps.length).toEqual(2);
      });
      currentUserService.capabilitiesForContext$('5').subscribe((caps) => {
        expect(caps.length).toEqual(1);
      });

      mockRequest();
    });

    it('Should filter by context and all actions', () => {
      currentUserService.hasCapabilities$('asdf/asdf').subscribe((hasCaps) => {
        expect(hasCaps).toEqual(false);
      });
      currentUserService.hasCapabilities$('placeholder_users/read').subscribe((hasCaps) => {
        expect(hasCaps).toEqual(true);
      });
      currentUserService.hasCapabilities$(['memberships/update', 'memberships/read'], '6').subscribe((hasCaps) => {
        expect(hasCaps).toEqual(true);
      });
      currentUserService.hasCapabilities$(['memberships/update', 'memberships/nonexistent'], '6').subscribe((hasCaps) => {
        expect(hasCaps).toEqual(false);
      });

      mockRequest();
    });

    it('Should filter by context and any of the actions', () => {
      currentUserService.hasAnyCapabilityOf$('memberships/update', '6').subscribe((hasCaps) => {
        expect(hasCaps).toEqual(true);
      });
      currentUserService.hasAnyCapabilityOf$(['memberships/update', 'memberships/read'], '6').subscribe((hasCaps) => {
        expect(hasCaps).toEqual(true);
      });
      currentUserService.hasAnyCapabilityOf$(['memberships/update', 'memberships/nonexistent'], '6').subscribe((hasCaps) => {
        expect(hasCaps).toEqual(true);
      });
      currentUserService.hasAnyCapabilityOf$('memberships/nonexistent', '6').subscribe((hasCaps) => {
        expect(hasCaps).toEqual(false);
      });

      mockRequest();
    });
  });
});
