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
// See docs/COPYRIGHT.rdoc for more details.
//++

import { Injectable } from '@angular/core';
import { FocusHelperService } from 'core-app/shared/directives/focus/focus-helper';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';

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
const accessibleListSelector = 'generic-table keyboard-accessible-list';

@Injectable({
  providedIn: 'root',
})
export class KeyboardShortcutService {
  // maybe move it to a .constant
  private shortcuts:any = {
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
    m: this.accessKey('moreMenu'),
    p: this.accessKey('projectSearch'),
    s: this.accessKey('quickSearch'),
    k: () => this.focusPrevItem(),
    j: () => this.focusNextItem(),
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
      // eslint-disable-next-line no-useless-concat
      const elem:HTMLElement = document.querySelectorAll("[accesskey='" + `${key}` + "']")[0] as HTMLElement;
      if (elem instanceof HTMLInputElement || elem.id === 'global-search-input') {
        // timeout with delay so that the key is not
        // triggered on the input
        setTimeout(() => this.FocusHelper.focus(jQuery(elem)), 200);
      } else if (elem.getAttribute('href')) {
        this.clickLink(elem);
      } else {
        elem.click();
      }
    };
  }

  public globalAction(action:keyof PathHelperService):() => void {
    return () => {
      const url = (this.PathHelper[action] as any)();
      window.location.href = url;
    };
  }

  public projectScoped(action:keyof PathHelperService):() => void {
    return () => {
      const projectIdentifier = this.currentProject.identifier;
      if (projectIdentifier) {
        const url = (this.PathHelper[action] as any)(projectIdentifier);
        window.location.href = url;
      }
    };
  }

  // eslint-disable-next-line class-methods-use-this
  clickLink(link:HTMLElement):void {
    if (!link.getAttribute('href')) {
      return;
    }

    const event = new MouseEvent('click', {
      view: window,
      bubbles: true,
      cancelable: true,
    });
    const cancelled = !link.dispatchEvent(event);

    if (!cancelled) {
      window.location.href = link.getAttribute('href') as string;
    }
  }

  showHelpModal():void {
    window.open(this.PathHelper.keyboardShortcutsHelpPath());
  }

  // eslint-disable-next-line class-methods-use-this
  focusItemOffset(offset:number):void {
    const list = document.getElementsByClassName(accessibleListSelector)[0];
    if (list === null) {
      return;
    }

    const rows:Element[] = Array.from(list.querySelectorAll('tbody > tr'));
    let index:number;
    if (document.activeElement) {
      index = rows.indexOf(document.activeElement);
      const target = rows[index + offset] as HTMLElement;
      target.focus();
    }
  }

  focusNextItem():void {
    this.focusItemOffset(1);
  }

  focusPrevItem():void {
    this.focusItemOffset(-1);
  }
}
