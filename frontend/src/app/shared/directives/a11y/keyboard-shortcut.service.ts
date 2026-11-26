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

import { Injectable, inject } from '@angular/core';
import { FocusHelperService } from 'core-app/shared/directives/focus/focus-helper';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { HotkeyDispatcher } from 'core-common/hotkeys/hotkey-dispatcher';

const accessKeys = {
  newWorkPackage: 2,
  edit: 3,
  quickSearch: 4,
  projectSearch: 5,
  help: 6,
  moreMenu: 7,
  details: 8,
};

type MenuTarget = 'overview'|'work-packages'|'activity'|'calendar-view'|'news'|'wiki';

const projectPaths = {
  overview: 'projectPath',
  'work-packages': 'workPackagesPath',
  activity: 'projectActivityPath',
  'calendar-view': 'projectCalendarPath',
  news: 'projectNewsPath',
  wiki: 'projectWikiPath',
} as const satisfies Record<MenuTarget, keyof PathHelperService>;

const globalPathSuffixes:Record<MenuTarget, string|null> = {
  overview: null,
  'work-packages': '/work_packages',
  activity: '/activity',
  'calendar-view': '/calendars',
  news: '/news',
  wiki: '/wiki_pages',
};

const projectMenuSelector = '#main-menu';
const modulesMenuSelector = '#op-app-header--modules-menu-list';
const quickAddWorkPackageSelector = '#op-app-header--quick-add-menu-list a[href*="/work_packages/new"]';

// this could be extracted into a separate component if it grows
const accessibleListSelector = 'table.keyboard-accessible-list';

@Injectable({
  providedIn: 'root',
})
export class KeyboardShortcutService {
  private readonly PathHelper = inject(PathHelperService);
  private readonly FocusHelper = inject(FocusHelperService);
  private readonly currentProject = inject(CurrentProjectService);
  private readonly configurationService = inject(ConfigurationService);

  private readonly dispatcher = new HotkeyDispatcher({
    '?': () => this.showHelpModal(),
    'Shift+?': () => this.showHelpModal(),
    'g m': () => Turbo.visit(this.PathHelper.myPagePath()),
    'g o': this.menuLink('overview'),
    'g w p': this.menuLink('work-packages'),
    'g w i': this.menuLink('wiki'),
    'g a': this.menuLink('activity'),
    'g c': this.menuLink('calendar-view'),
    'g n': this.menuLink('news'),
    'n w p': this.newWorkPackage(),

    'g e': this.accessKey('edit'),
    'd w p': this.accessKey('details'),
    'm': this.accessKey('moreMenu'),
    'p': this.accessKey('projectSearch'),
    's': this.accessKey('quickSearch'),
    'k': () => this.focusPrevItem(),
    'j': () => this.focusNextItem(),
  }, { repeat: ['j', 'k'] });

  /**
   * Register the keyboard shortcuts.
   */
  public register():void {
    void this.configurationService.initialize().then(() => {
      if (!this.configurationService.disableKeyboardShortcuts()) {
        this.dispatcher.start();
      }
    });
  }

  public accessKey(keyName:keyof typeof accessKeys):() => void {
    return () => {
      const elem = this.accessKeyOwner(keyName);
      if (elem) {
        this.activate(elem);
      }
    };
  }

  /**
   * Activates the create button of the page, or else opens the new work package form
   * for the first type offered by the quick-add menu of the header.
   */
  public newWorkPackage():() => void {
    return () => {
      const createButton = this.accessKeyOwner('newWorkPackage');
      if (createButton?.checkVisibility()) {
        this.activate(createButton);
      } else {
        document.querySelector<HTMLAnchorElement>(quickAddWorkPackageSelector)?.click();
      }
    };
  }

  /**
   * Opens the page behind a menu item: the project's page inside a project, the global page outside of one.
   * Does nothing when the menu that is rendered does not offer the page, for example for a disabled module.
   */
  public menuLink(target:MenuTarget):() => void {
    return ():void => {
      const projectIdentifier = this.currentProject.identifier;
      if (projectIdentifier) {
        this.openProjectPage(target, projectIdentifier);
      } else {
        this.openGlobalPage(target);
      }
    };
  }

  private accessKeyOwner(keyName:keyof typeof accessKeys):HTMLElement|undefined {
    const candidates = Array.from(document.querySelectorAll<HTMLElement>(`[accesskey="${accessKeys[keyName]}"]`));
    return candidates.find((candidate) => candidate.checkVisibility()) ?? candidates[0];
  }

  private activate(elem:HTMLElement):void {
    if (elem instanceof HTMLInputElement || elem.getAttribute('id') === 'global-search-input') {
      this.FocusHelper.focus(elem);
    } else {
      elem.click();
    }
  }

  private openProjectPage(target:MenuTarget, projectIdentifier:string):void {
    const projectPath = this.PathHelper[projectPaths[target]](projectIdentifier);
    const menu = document.querySelector(projectMenuSelector);
    if (!menu) {
      Turbo.visit(projectPath);
    } else if (target === 'wiki') {
      if (menu.querySelector('a.wiki-menu--main-item')) {
        Turbo.visit(projectPath);
      }
    } else {
      menu.querySelector<HTMLAnchorElement>(`a.${target}-menu-item`)?.click();
    }
  }

  private openGlobalPage(target:MenuTarget):void {
    const suffix = globalPathSuffixes[target];
    if (suffix) {
      document.querySelector<HTMLAnchorElement>(`${modulesMenuSelector} a[href$="${suffix}"]`)?.click();
    }
  }

  showHelpModal():void {
    window.open(this.PathHelper.keyboardShortcutsHelpPath());
  }

  focusItemOffset(offset:number):void {
    const active = document.activeElement;
    const enclosing = active?.closest(accessibleListSelector) ?? null;
    const list = enclosing ?? this.nearestList(active, offset);
    if (!list) {
      return;
    }

    const rows = Array.from(list.querySelectorAll<HTMLTableRowElement>('tbody.work-package--results-tbody > tr, tbody > tr.wp-table--sums-row'))
      .filter((row) => row.checkVisibility());
    const current = enclosing ? active?.closest('tr') ?? null : null;
    const index = current ? rows.indexOf(current) : -1;
    const start = !enclosing && offset < 0 ? rows.length : index;
    for (let next = start + offset; next >= 0 && next < rows.length; next += offset) {
      if (!rows[next].classList.contains('wp-table--sums-row')) {
        rows[next].focus();
        return;
      }
    }
  }

  private nearestList(active:Element|null, offset:number):Element|null {
    const lists = Array.from(document.querySelectorAll(accessibleListSelector)).filter((list) => list.checkVisibility());
    const side = offset > 0 ? Node.DOCUMENT_POSITION_FOLLOWING : Node.DOCUMENT_POSITION_PRECEDING;
    const onSide = active ? lists.filter((list) => (active.compareDocumentPosition(list) & side) !== 0) : [];

    return offset > 0
      ? onSide[0] ?? lists[0] ?? null
      : onSide.at(-1) ?? lists.at(-1) ?? null;
  }

  focusNextItem():void {
    this.focusItemOffset(1);
  }

  focusPrevItem():void {
    this.focusItemOffset(-1);
  }
}
