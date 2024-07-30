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

import { GonService } from 'core-app/core/gon/gon.service';
import { Injectable } from '@angular/core';
import { input } from '@openproject/reactivestates';

export interface HideSectionDefinition {
  key:string;
  label:string;
}

@Injectable({ providedIn: 'root' })
export class HideSectionService {
  public displayed = input<string[]>();

  public all:HideSectionDefinition[] = [];

  constructor(Gon:GonService) {
    const sections:any = Gon.get('hideSections');
    this.all = sections.all;
    this.displayed.putValue(sections.active.map((el:HideSectionDefinition) => {
      this.toggleVisibility(el.key, true);
      return el.key;
    }));

    this.removeHiddenOnSubmit();
  }

  section(key:string):HTMLElement|null {
    return document.querySelector(`section.hide-section[data-section-name="${key}"]`);
  }

  hide(key:string) {
    this.displayed.doModify((displayed) => displayed.filter((el) => el !== key));
    this.toggleVisibility(key, false);
  }

  show(key:string) {
    this.displayed.doModify((displayed) => [...displayed, key]);
    this.toggleVisibility(key, true);
  }

  private toggleVisibility(key:string, visible:boolean) {
    const section = this.section(key);

    if (section) {
      section.hidden = !visible;
    }
  }

  private removeHiddenOnSubmit() {
    jQuery(document.body)
      .on('submit', 'form', function (evt:any) {
        const form = jQuery(this);
        const sections = form.find('section.hide-section:hidden');

        if (form.data('hideSectionRemoved') || sections.length === 0) {
          return true;
        }

        form.data('hideSectionRemoved', true);
        sections.remove();
        form.trigger('submit');
        evt.preventDefault();
        return false;
      });
  }
}
