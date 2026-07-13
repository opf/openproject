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

import { Injectable, inject } from '@angular/core';
import { DOCUMENT } from '@angular/common';
import { isVisible } from 'core-app/shared/helpers/dom-helpers';

export const ANIMATION_RATE_MS = 100;

@Injectable({ providedIn: 'root' })
export class TopMenuService {
  private document = inject<Document>(DOCUMENT);


  register():void {
    this.skipContentClickListener();
  }

  private skipContentClickListener():void {
    // Skip menu on content
    const skipLink = this.document.querySelector('#skip-navigation--content');
    skipLink?.addEventListener('click', () => {
      // Skip to the breadcrumb or the first link in the toolbar or the first link in the content (homescreen)
      const selectors = '.first-breadcrumb-element a, .toolbar-container a:first-of-type, #content a:first-of-type';
      const visibleLink = Array
        .from(document.querySelectorAll<HTMLElement>(selectors))
        .find((link) => isVisible(link));

      visibleLink?.focus();
    });
  }
}
