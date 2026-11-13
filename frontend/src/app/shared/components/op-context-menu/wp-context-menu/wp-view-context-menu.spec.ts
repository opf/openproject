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

import { Injector } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { States } from 'core-app/core/states/states.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';
import { TurboRequestsService } from 'core-app/core/turbo/turbo-requests.service';
import { CopyToClipboardService } from 'core-app/shared/components/copy-to-clipboard/copy-to-clipboard.service';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { WorkPackageContextMenuHelperService } from 'core-app/features/work-packages/components/wp-table/context-menu-helper/wp-context-menu-helper.service';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { WorkPackageViewContextMenu } from './wp-view-context-menu.directive';

describe('WorkPackageViewContextMenu', () => {
  let injector:Injector;
  let host:HTMLElement;

  const workPackage = { id: '1', displayId: 'PROJ-1', project: { id: '1' } };

  beforeEach(() => {
    window.I18n.store({ en: { js: { button_open_fullscreen: 'Open full screen', button_open_details: 'Open details' } } });
    TestBed.configureTestingModule({
      providers: [
        { provide: OPContextMenuService, useValue: {} },
        { provide: CopyToClipboardService, useValue: { copy: vi.fn() } },
        { provide: States, useValue: { workPackages: { get: () => ({ value: workPackage }) } } },
        { provide: WorkPackageViewSelectionService, useValue: { isSelected: () => false } },
        {
          provide: WorkPackageContextMenuHelperService,
          useValue: {
            getPermittedActions: () => [
              { key: 'delete', text: 'Delete', icon: 'icon-delete' },
              { key: 'plugin', text: 'Plugin', icon: 'icon-unknown-plugin' },
            ],
          },
        },
        { provide: CurrentProjectService, useValue: { identifier: 'proj' } },
        { provide: PathHelperService, useValue: { genericWorkPackagePath: () => '/wp/1', staticBase: '' } },
        { provide: UrlParamsService, useValue: { basePathWithoutDetails: () => '/work_packages' } },
        { provide: TurboRequestsService, useValue: {} },
      ],
    });
    injector = TestBed.inject(Injector);
    host = document.createElement('div');
    document.body.append(host);
  });

  afterEach(() => host.remove());

  const cardTarget = () => {
    host.innerHTML = '<div class="op-wp-single-card" tabindex="0"><div><span class="subject">Subject</span></div></div>';
    return { root: host.querySelector<HTMLElement>('.op-wp-single-card')!, target: host.querySelector<HTMLElement>('.subject')! };
  };

  const eventTarget = () => {
    host.innerHTML = '<a class="fc-event" tabindex="0"><div class="fc-event-main"><div class="fc-event-title">Event</div></div></a>';
    return { root: host.querySelector<HTMLElement>('.fc-event')!, target: host.querySelector<HTMLElement>('.fc-event-title')! };
  };

  const scenarios = [
    ['a card subject', cardTarget],
    ['a calendar event title', eventTarget],
  ] as const;

  it('gives every item an octicon or no icon, never a Spot icon', () => {
    const { target } = cardTarget();
    const items = new WorkPackageViewContextMenu(injector, '1', target).locals.items;

    expect(items.length).toBeGreaterThan(2);
    expect(items.every((item) => item.icon === undefined)).toBe(true);
    expect(items.find((item) => item.linkText === 'Delete')?.octicon).toBe('trash');
    expect(items.find((item) => item.linkText === 'Plugin')?.octicon).toBeUndefined();
  });

  describe.each(scenarios)('opened on %s', (_name, build) => {
    let root:HTMLElement;
    let menu:WorkPackageViewContextMenu;

    beforeEach(() => {
      const built = build();
      ({ root } = built);
      menu = new WorkPackageViewContextMenu(injector, '1', built.target);
      (document.activeElement as HTMLElement | null)?.blur();
    });

    it('focuses the focusable ancestor on escape', () => {
      menu.onClose(false, 'escape');

      expect(root).toHaveFocus();
    });

    it('focuses the focusable ancestor after an action when focus was lost', () => {
      menu.onClose(false, 'action');

      expect(root).toHaveFocus();
    });

    it('leaves focus alone when the menu closed from outside', () => {
      menu.onClose(false, 'outside');

      expect(root).not.toHaveFocus();
    });

    it('applies the legacy focus rule without a reason', () => {
      menu.onClose(true);

      expect(root).toHaveFocus();
    });
  });
});
