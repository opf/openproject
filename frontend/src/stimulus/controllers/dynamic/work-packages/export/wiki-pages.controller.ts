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

import { Controller } from '@hotwired/stimulus';

interface CheckedNodePayload {
  path?:string[];
  nodeId?:string;
  value?:string;
}

interface WikiPageOption {
  id:string;
  name:string;
}

export default class WikiPagesController extends Controller {
  static targets = ['autocompleter', 'dialog', 'treeContainer', 'treeTemplate'];

  static values = {
    providerId: String,
  };

  declare readonly autocompleterTarget:HTMLElement;
  declare readonly dialogTarget:HTMLDialogElement;
  declare readonly treeContainerTarget:HTMLElement;
  declare readonly treeTemplateTarget:HTMLTemplateElement;
  declare readonly providerIdValue:string;

  add(event:Event):void {
    event.preventDefault();

    // The autocompleter owns the list: it de-duplicates, orders and renders the inputs.
    this.autocompleterTarget.dispatchEvent(
      new CustomEvent<WikiPageOption[]>('op:draggable-autocompleter:add', { detail: this.selectedPages() }),
    );

    this.dialogTarget.close();
  }

  // The dialog is a picker, not an editor of the list: every open starts from a clean
  // tree, so "Selected" means "checked since this dialog opened".
  resetTree():void {
    this.treeContainerTarget.replaceChildren(this.treeTemplateTarget.content.cloneNode(true));
  }

  private selectedPages():WikiPageOption[] {
    const inputs = this.treeContainerTarget.querySelectorAll<HTMLInputElement>('input[type=hidden]');

    return Array.from(inputs)
      .map((input) => this.pageFrom(input.value))
      .filter((page):page is WikiPageOption => page !== null);
  }

  // The node id is "<type>:<identifier>"; only pages are selectable, and the stored
  // reference qualifies the identifier with the wiki provider instead.
  private pageFrom(value:string):WikiPageOption|null {
    if (!value.startsWith('{')) return null;

    let payload:CheckedNodePayload;
    try {
      payload = JSON.parse(value) as CheckedNodePayload;
    } catch {
      return null;
    }

    const [type, identifier] = (payload.nodeId ?? '').split(':');
    if (type !== 'page' || !identifier) return null;

    return {
      id: `${this.providerIdValue}:${identifier}`,
      name: this.labelFor(payload.path ?? []),
    };
  }

  // A node's path is its own label preceded by its ancestors', the outermost being the
  // project the wiki belongs to.
  private labelFor(path:string[]):string {
    if (path.length === 0) return '';
    if (path.length === 1) return path[0];

    return `${path[0]}: ${path[path.length - 1]}`;
  }
}
