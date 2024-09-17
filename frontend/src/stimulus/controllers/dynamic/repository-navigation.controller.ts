/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
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
import { HttpClient } from '@angular/common/http';

export default class RepositoryNavigationController extends Controller {
  static targets = [
    'revision',
    'branch',
    'tag',
    'form',
    'repoBrowser',
  ];

  declare readonly branchTarget:HTMLSelectElement;

  declare readonly hasBranchTarget:boolean;

  declare readonly revisionTarget:HTMLSelectElement;

  declare readonly tagTarget:HTMLSelectElement;

  declare readonly hasTagTaget:boolean;

  declare readonly formTarget:HTMLFormElement;

  declare readonly repoBrowserTarget:HTMLFormElement;

  private http:HttpClient;

  async connect() {
    // If we're viewing a tag or branch, don't display it in the revision box
    if (this.tagSelected || this.branchSelected) {
      this.revisionTarget.value = '';
    }

    const context = await window.OpenProject.getPluginContext();
    this.http = context.services.http;
  }

  sendForm() {
    if (this.hasBranchTarget) {
      this.branchTarget.disabled = true;
    }
    if (this.hasTagTaget) {
      this.tagTarget.disabled = true;
    }
    this.formTarget.submit();

    if (this.hasBranchTarget) {
      this.branchTarget.disabled = false;
    }
    if (this.hasTagTaget) {
      this.tagTarget.disabled = false;
    }
  }

  /**
   Copy the branch/tag value into the revision box, then disable
   the dropdowns before submitting the form
   */
  applyValue(evt:InputEvent) {
    this.revisionTarget.value = (evt.target as HTMLSelectElement).value;
    this.sendForm();
  }

  toggleDirectory(evt:MouseEvent) {
    const el = (evt.target as HTMLElement).closest('a') as HTMLAnchorElement;
    const id = el.dataset.element as string;
    const content = document.getElementById(id) as HTMLElement;

    if (this.expandDir(content)) {
      content.classList.add('loading');

      this
        .http
        .get(el.dataset.url as string, { responseType: 'text' })
        .subscribe((response:string) => {
          content.insertAdjacentHTML('afterend', response);
          content.classList.remove('loading');
          this.expandItem(content);
        });
    }
  }

  private get branchSelected():boolean {
    return this.hasBranchTarget && this.branchTarget.value === this.revisionTarget.value;
  }

  private get tagSelected():boolean {
    return this.hasTagTaget && this.tagTarget.value === this.revisionTarget.value;
  }

  /**
   * Determines whether a dir-expander should load content
   * or simply expand already loaded content.
   */
  private expandDir(content:HTMLElement) {
    if (content.classList.contains('open')) {
      this.collapseScmEntry(content);
      return false;
    }

    if (content.classList.contains('loaded')) {
      this.expandScmEntry(content);
      return false;
    }

    return !content.classList.contains('loading');
  }

  /**
   * Collapses a directory listing in the repository module
   */
  private collapseScmEntry(content:HTMLElement) {
    this
      .repoBrowserTarget
      .querySelectorAll(`.${content.id}`)
      .forEach((el:HTMLElement) => {
        if (el.classList.contains('open')) {
          this.collapseScmEntry(el);
        }

        el.style.display = 'none';
        this.collapseItem(el);
      });

    this.collapseItem(content);
  }

  /**
   * Expands an SCM entry if its loaded
   */
  private expandScmEntry(content:HTMLElement) {
    this
      .repoBrowserTarget
      .querySelectorAll(`.${content.id}`)
      .forEach((el:HTMLElement) => {
        el.style.removeProperty('display');
        if (el.classList.contains('loaded') && !el.classList.contains('collapsed')) {
          this.expandScmEntry(el);
        }

        this.collapseItem(el);
      });

    this.expandItem(content);
  }

  private expandItem(el:HTMLElement) {
    el.classList.add('open');
    el.classList.remove('collapsed');

    const expander = el.querySelector<HTMLElement>('a.dir-expander');
    if (expander) {
      expander.title = I18n.t('js.label_collapse');
    }
  }

  private collapseItem(el:HTMLElement) {
    el.classList.remove('open');
    el.classList.add('collapsed');

    const expander = el.querySelector<HTMLElement>('a.dir-expander');
    if (expander) {
      expander.title = I18n.t('js.label_expand');
    }
  }
}
