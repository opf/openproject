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

import { TestBed } from '@angular/core/testing';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ColorsService } from 'core-app/shared/components/colors/colors.service';
import { PrincipalRendererService } from './principal-renderer.service';

describe('PrincipalRendererService', () => {
  let service:PrincipalRendererService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        PrincipalRendererService,
        ColorsService,
        { provide: PathHelperService, useValue: {} },
        { provide: ApiV3Service, useValue: {} },
      ],
    });

    service = TestBed.inject(PrincipalRendererService);
  });

  describe('fallback avatar initials', () => {
    const renderFallback = (name:string):string|null => {
      const container = document.createElement('div');

      service.render(
        container,
        { id: '1', name, href: '/api/v3/placeholder_users/1' },
        { hide: true, link: false },
        { hide: false, size: 'default' },
        { isActivated: false },
      );

      return container.querySelector('.op-avatar--fallback')?.textContent ?? null;
    };

    it('uses the first letters of first and last name', () => {
      expect(renderFallback('John Doe')).toBe('JD');
    });

    it('uses a single initial when there is no last name', () => {
      expect(renderFallback('Madonna')).toBe('M');
    });

    it('keeps emoji first names as complete code points', () => {
      expect(renderFallback('🤖 Oliver')).toBe('🤖O');
    });

    it('keeps emoji last names as complete code points', () => {
      expect(renderFallback('Oliver 🤖')).toBe('O🤖');
    });

    it('keeps emoji-only names as complete code points', () => {
      expect(renderFallback('🤖')).toBe('🤖');
    });
  });
});
