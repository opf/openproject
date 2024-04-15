/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) 2010-2024 the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { Controller } from '@hotwired/stimulus';

export default class ParamsFromQueryController extends Controller {
  static targets = [
    'anchor',
    'form',
  ];

  declare readonly hasFormTarget:boolean;
  declare readonly hasAnchorTarget:boolean;

  static values = {
    allAnchors: Boolean,
    allowed: Array,
  };

  declare allAnchorsValue:boolean;
  declare allowedValue:string[];

  initialize() {
    if (this.allAnchorsValue) {
      this.element.querySelectorAll('a').forEach((target) => {
        this.appendParamsToHref(target);
      });
    }
  }

  connect() {
    if (this.element.tagName === 'FORM' && !this.hasFormTarget) {
      this.addFieldsToForm(this.element as HTMLFormElement);
    } else if (this.element.tagName === 'A' && !this.hasAnchorTarget) {
     this.appendParamsToHref(this.element as HTMLAnchorElement);
    }
  }

  anchorTargetConnected(target:HTMLAnchorElement) {
    this.appendParamsToHref(target);
  }

  formTargetConnected(target:HTMLFormElement) {
    this.addFieldsToForm(target);
  }

  appendParamsToHref(target:HTMLAnchorElement) {
    const currentHref = target.getAttribute('href') || '';
    const currentHrefParams = new URLSearchParams(currentHref.split('?')[1] || '');

    this.forEachMatchingUrlParam((key, value) => {
      currentHrefParams.append(key, value);
    });

    target.setAttribute('href', `${currentHref.split('?')[0]}?${currentHrefParams.toString()}`);
  }

  addFieldsToForm(form:HTMLFormElement) {
    this.forEachMatchingUrlParam((key, value) => {
      const filterElement = document.createElement('input');
      filterElement.type = 'hidden';
      filterElement.name = key;
      filterElement.value = value;

      form.appendChild(filterElement);
    });

    return true;
  }

  private forEachMatchingUrlParam(callback:(key:string, value:string) => void) {
    const paramsString = window.location.search.substring(1);
    const searchParams = new URLSearchParams(paramsString);

    searchParams.forEach((value, key) => {
      this.allowedValue.forEach((allowedKey) => {
        if (key.startsWith(allowedKey)) {
          callback(key, value);
        }
      });
    });
  }
}
