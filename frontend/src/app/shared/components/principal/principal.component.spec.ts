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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Component } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { vi, type Mock } from 'vitest';
import { defineTestCustomElement, TestCustomElement } from 'core-app/shared/helpers/angular/custom-element.spec-helper';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { PrincipalsResourceService } from 'core-app/core/state/principals/principals.service';
import { OpPrincipalComponent } from './principal.component';
import { PrincipalRendererService } from './principal-renderer.service';
import { OpenprojectPrincipalRenderingModule } from './principal-rendering.module';
import { PrincipalLike } from './principal-types';

const principal:PrincipalLike = { name: 'Ann', href: '/api/v3/users/1', id: '1' };

@Component({
  template: '<op-principal [principal]="principal" [link]="false" />',
  imports: [OpenprojectPrincipalRenderingModule],
})
class HostComponent {
  principal = principal;
}

describe('OpPrincipalComponent', () => {
  let render:Mock<PrincipalRendererService['render']>;

  const lastCall = () => {
    const call = render.mock.lastCall;
    if (!call) throw new Error('render was not called');
    return call;
  };

  beforeEach(() => {
    render = vi.fn();
    TestBed.configureTestingModule({
      imports: [HostComponent],
      providers: [
        { provide: I18nService, useValue: {} },
        { provide: PathHelperService, useValue: {} },
        { provide: ApiV3Service, useValue: {} },
        { provide: TimezoneService, useValue: {} },
        { provide: PrincipalsResourceService, useValue: {} },
      ],
    });
    TestBed.overrideProvider(PrincipalRendererService, { useValue: { render } });
  });

  describe('as a custom element', () => {
    let element:TestCustomElement;

    beforeEach(async () => {
      element = await defineTestCustomElement(OpPrincipalComponent, {
        principal: JSON.stringify({ name: 'Ann', href: '/api/v3/users/1', id: 1 }),
        'hide-name': null,
        link: 'false',
      });
    });

    afterEach(() => element.element.remove());

    it('parses plain attribute strings into typed inputs', () => {
      const [, renderedPrincipal, name] = lastCall();

      expect(renderedPrincipal).toEqual({ name: 'Ann', href: '/api/v3/users/1', id: 1 });
      expect(name?.link).toBe(false);
      expect(name?.hide).toBe(false);
    });

    it('re-renders when an attribute is set', async () => {
      await element.set('hide-name', '');

      expect(lastCall()[2]?.hide).toBe(true);
    });

    it('falls back to the default when an attribute is removed', async () => {
      await element.set('hover-card', 'false');
      expect(lastCall()[4]?.isActivated).toBe(false);

      await element.remove('hover-card');

      expect(lastCall()[4]?.isActivated).toBe(true);
    });

    it('falls back to the default size for unknown values', async () => {
      await element.set('size', 'bogus');

      expect(lastCall()[3]?.size).toBe('default');
    });

    it('passes the name title through', async () => {
      await element.set('name-title', 'Ann (away)');

      expect(lastCall()[5]).toBe('Ann (away)');
    });
  });

  describe('in an Angular template', () => {
    it('renders with bound inputs', async () => {
      const fixture = TestBed.createComponent(HostComponent);
      await fixture.whenStable();

      const [, renderedPrincipal, name] = lastCall();
      expect(renderedPrincipal).toEqual(principal);
      expect(name?.link).toBe(false);
      fixture.destroy();
    });
  });
});
