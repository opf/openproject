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

import { TestBed } from '@angular/core/testing';
import { A11yModule } from '@angular/cdk/a11y';
import { PortalModule } from '@angular/cdk/portal';
import { OpModalOverlayComponent } from 'core-app/shared/components/modal/modal-overlay.component';
import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';

describe('OpModalOverlayComponent', () => {
  function focusTrapAnchors(host:HTMLElement):HTMLElement[] {
    return Array.from(host.querySelectorAll<HTMLElement>('.cdk-focus-trap-anchor'));
  }

  function setup() {
    TestBed.configureTestingModule({
      imports: [A11yModule, PortalModule],
      declarations: [OpModalOverlayComponent],
    });

    const fixture = TestBed.createComponent(OpModalOverlayComponent);
    fixture.detectChanges();

    return {
      fixture,
      host: fixture.nativeElement as HTMLElement,
      modalService: TestBed.inject(OpModalService),
    };
  }

  it('keeps the focus trap anchors unfocusable while no modal is open', () => {
    const { host } = setup();

    const anchors = focusTrapAnchors(host);
    expect(anchors).toHaveLength(2);
    anchors.forEach((anchor) => {
      expect(anchor).toHaveAttribute('aria-hidden', 'true');
      expect(anchor).not.toHaveAttribute('tabindex');
    });
  });

  it('enables the focus trap anchors while a modal is open', () => {
    const { fixture, host, modalService } = setup();

    modalService.activeModalInstance$.next({} as OpModalComponent);
    fixture.detectChanges();

    focusTrapAnchors(host).forEach((anchor) => {
      expect(anchor).toHaveAttribute('tabindex', '0');
    });
  });
});
