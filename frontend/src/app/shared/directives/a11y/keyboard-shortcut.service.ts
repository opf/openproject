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

import { Injectable } from '@angular/core';
import { FocusHelperService } from 'core-app/shared/directives/focus/focus-helper';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import * as Mousetrap from 'mousetrap';

const accessKeys = {
  preview: 1,
  newWorkPackage: 2,
  edit: 3,
  quickSearch: 4,
  projectSearch: 5,
  help: 6,
  moreMenu: 7,
  details: 8,
};

// this could be extracted into a separate component if it grows
const accessibleListSelector = 'table.keyboard-accessible-list';
const accessibleRowSelector = 'table.keyboard-accessible-list tbody tr';

@Injectable({
  providedIn: 'root',
})
export class KeyboardShortcutService {
  // maybe move it to a .constant
  private shortcuts:{ [name:string]:() => void } = {
    /* eslint-disable quote-props */
    '?': () => this.showHelpModal(),
    'g m': this.globalAction('myPagePath'),
    'g o': this.projectScoped('projectPath'),
    'g w p': this.projectScoped('projectWorkPackagesPath'),
    'g w i': this.projectScoped('projectWikiPath'),
    'g a': this.projectScoped('projectActivityPath'),
    'g c': this.projectScoped('projectCalendarPath'),
    'g n': this.projectScoped('projectNewsPath'),
    'n w p': this.projectScoped('projectWorkPackageNewPath'),

    'g e': this.accessKey('edit'),
    'g p': this.accessKey('preview'),
    'd w p': this.accessKey('details'),
    'm': this.accessKey('moreMenu'),
    'p': this.accessKey('projectSearch'),
    's': this.accessKey('quickSearch'),
    'k': () => this.focusPrevItem(),
    'j': () => this.focusNextItem(),
    /* eslint-enable quote-props */
  };

  constructor(private readonly PathHelper:PathHelperService,
    private readonly FocusHelper:FocusHelperService,
    private readonly currentProject:CurrentProjectService) {
    this.register();
  }

  /**
   * Register the keyboard shortcuts.
   */
  public register():void {
    _.each(this.shortcuts, (action:() => void, key:string) => Mousetrap.bind(key, action));
  }

  public accessKey(keyName:'preview'|'newWorkPackage'|'edit'|'quickSearch'|'projectSearch'|'help'|'moreMenu'|'details'):() => void {
    const key = accessKeys[keyName];

    return () => {
      const elem = jQuery(`[accesskey=${key}]:first`);
      if (elem.is('input') || elem.attr('id') === 'global-search-input') {
        // timeout with delay so that the key is not
        // triggered on the input
        setTimeout(() => this.FocusHelper.focus(elem[0]), 200);
      } else if (elem.is('[href]')) {
        this.clickLink(elem[0] as HTMLLinkElement);
      } else {
        elem[0].click();
      }
    };
  }

  public globalAction(action:keyof PathHelperService) {
    return ():void => {
      window.location.href = (this.PathHelper[action] as () => string)();
    };
  }

  public projectScoped(action:keyof PathHelperService) {
    return ():void => {
      const projectIdentifier = this.currentProject.identifier;
      if (projectIdentifier) {
        window.location.href = (this.PathHelper[action] as (identifier:string|null) => string)(projectIdentifier);
      }
    };
  }

  // eslint-disable-next-line class-methods-use-this
  clickLink(link:HTMLLinkElement):void {
    const event = new MouseEvent('click', {
      view: window,
      bubbles: true,
      cancelable: true,
    });
    const cancelled = !link.dispatchEvent(event);

    if (!cancelled) {
      window.location.href = link.href;
    }
  }

  showHelpModal():void {
    window.open(this.PathHelper.keyboardShortcutsHelpPath());
  }

  focusItemOffset(offset:number):void {
    const list = document.querySelector(accessibleListSelector);
    if (!list) {
      return;
    }

    const rows:HTMLElement[] = Array.from(list.querySelectorAll('tbody > tr'));
    let index:number;
    if (document.activeElement) {
      index = rows.indexOf(document.activeElement as HTMLElement);
      const target = rows[index + offset];
      target?.focus();
    }
  }

  focusNextItem():void {
    this.focusItemOffset(1);
  }

  focusPrevItem():void {
    this.focusItemOffset(-1);
  }
}
