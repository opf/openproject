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

/* jshint expr: true */

import { TestBed } from '@angular/core/testing';
import {
  HttpClientTestingModule,
  HttpTestingController,
} from '@angular/common/http/testing';
import { States } from 'core-app/core/states/states.service';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { CapabilitiesResourceService } from 'core-app/core/state/capabilities/capabilities.service';
import {
  CurrentUser,
  CurrentUserStore,
} from 'core-app/core/current-user/current-user.store';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { ICapability } from 'core-app/core/state/capabilities/capability.model';
import * as URI from 'urijs';
import { ApiV3ListParameters } from 'core-app/core/apiv3/paths/apiv3-list-resource.interface';
import { CurrentUserQuery } from 'core-app/core/current-user/current-user.query';

const globalCapability:ICapability = {
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

const projectCapabilityp63Update:ICapability = {
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

const projectCapabilityp63Read:ICapability = {
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

const projectCapabilityp53Update:ICapability = {
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

describe('Capabilities service', () => {
  let currentUser:CurrentUserService;
  let service:CapabilitiesResourceService;
  let httpMock:HttpTestingController;

  const compile = (user:CurrentUser) => {
    const ConfigurationServiceStub = {};

    TestBed.configureTestingModule({
      imports: [
        HttpClientTestingModule,
      ],
      providers: [
        HalResourceService,
        { provide: ConfigurationService, useValue: ConfigurationServiceStub },
        { provide: States, useValue: new States() },
        CapabilitiesResourceService,
        CurrentUserStore,
        CurrentUserQuery,
        CurrentUserService,
      ],
    });

    currentUser = TestBed.inject(CurrentUserService);
    currentUser.setUser(user);

    service = TestBed.inject(CapabilitiesResourceService);
    httpMock = TestBed.inject(HttpTestingController);
  };

  const mockRequest = () => {
    httpMock
      .match((req) => req.url.includes('/api/v3/capabilities'))
      .forEach((req) => {
        expect(req.request.method).toBe('GET');
        const url = URI(req.request.url);
        const filterParams = new URLSearchParams(url.query()).get('filters') as string;
        const context = JSON.parse(filterParams)[1].context.values[0] as string;
        let elements:ICapability[];

        switch (context) {
          case 'g':
            elements = [globalCapability];
            break;
          case 'p6':
            elements = [projectCapabilityp63Read, projectCapabilityp63Update];
            break;
          case 'p5':
            elements = [projectCapabilityp53Update];
            break;
          default:
            elements = [];
            break;
        }

        req.flush({
          _type: 'Collection',
          count: 4,
          total: 4,
          pageSize: 1000,
          offset: 1,
          _embedded: {
            elements,
          },
        });
      });
  };

  afterEach(() => {
    httpMock.verify();
  });

  describe('When not logged in', () => {
    beforeEach(() => compile({ id: null, name: null, loggedIn: false }));

    it('Should have no capabilities', () => {
      service.loadedCapabilities$('global').subscribe((caps) => {
        expect(caps.length).toEqual(0);
      });

      mockRequest();
    });
  });

  describe('When logged in', () => {
    beforeEach(() => compile({ id: '1', name: 'Admin', loggedIn: true }));

    it('Should have all capabilities', () => {
      const params:ApiV3ListParameters = {
        filters: [['principal', '=', ['1']], ['context', '=', ['g']]],
      };

      service
        .requireCollection(params)
        .subscribe((caps) => {
          expect(caps.length).toEqual(1);
        });

      mockRequest();
    });

    it('Should filter by context', () => {
      let params:ApiV3ListParameters = {
        filters: [['principal', '=', ['1']], ['context', '=', ['g']]],
      };

      service
        .requireCollection(params)
        .subscribe((caps) => {
          expect(caps.length).toEqual(1);
        });

      params = {
        filters: [['principal', '=', ['1']], ['context', '=', ['p6']]],
      };

      service
        .requireCollection(params)
        .subscribe((caps) => {
          expect(caps.length).toEqual(2);
        });

      params = {
        filters: [['principal', '=', ['1']], ['context', '=', ['p5']]],
      };

      service
        .requireCollection(params)
        .subscribe((caps) => {
          expect(caps.length).toEqual(1);
        });

      mockRequest();
    });

    it('Should filter by context and all actions', () => {
      currentUser.hasCapabilities$('asdf/asdf', 'global').subscribe((hasCaps) => {
        expect(hasCaps).toEqual(false);
      });
      currentUser.hasCapabilities$('placeholder_users/read', 'global').subscribe((hasCaps) => {
        expect(hasCaps).toEqual(true);
      });
      currentUser.hasCapabilities$(['memberships/update', 'memberships/read'], '6').subscribe((hasCaps) => {
        expect(hasCaps).toEqual(true);
      });
      currentUser.hasCapabilities$(['memberships/update', 'memberships/nonexistent'], '6').subscribe((hasCaps) => {
        expect(hasCaps).toEqual(false);
      });

      mockRequest();
    });

    it('Should filter by context and any of the actions', () => {
      currentUser.hasAnyCapabilityOf$('memberships/update', '6').subscribe((hasCaps) => {
        expect(hasCaps).toEqual(true);
      });
      currentUser.hasAnyCapabilityOf$(['memberships/update', 'memberships/read'], '6').subscribe((hasCaps) => {
        expect(hasCaps).toEqual(true);
      });
      currentUser.hasAnyCapabilityOf$(['memberships/update', 'memberships/nonexistent'], '6').subscribe((hasCaps) => {
        expect(hasCaps).toEqual(true);
      });
      currentUser.hasAnyCapabilityOf$('memberships/nonexistent', '6').subscribe((hasCaps) => {
        expect(hasCaps).toEqual(false);
      });

      mockRequest();
    });
  });
});
