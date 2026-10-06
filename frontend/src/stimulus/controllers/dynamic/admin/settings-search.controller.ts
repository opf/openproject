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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ApplicationController } from 'stimulus-use';

type FilterFn = (node:HTMLElement, query:string, filterMode?:string) => Range[]|null;

interface FilterableTreeViewElement extends HTMLElement {
  filterFn:FilterFn;
}

// Matches every word of the query regardless of order and punctuation
// (e.g. "self registration" finds "Self-registration") against a node's own
// text and the labels of its ancestors, so searching for a menu item or tab
// lists all settings below it.
export default class SettingsSearchController extends ApplicationController {
  connect() {
    const treeView = this.element.querySelector<FilterableTreeViewElement>('filterable-tree-view');
    if (!treeView) return;

    treeView.filterFn = (node, query) => this.filter(node, query);
  }

  private filter(node:HTMLElement, query:string):Range[]|null {
    const words = this.words(query);
    if (words.length === 0) return [];

    const ownWords = this.words(node.textContent ?? '');
    const ancestorWords = this.words(this.ancestorLabels(node).join(' '));
    const searchable = [...ownWords, ...ancestorWords];

    const matches = words.every((word) => searchable.some((candidate) => candidate.includes(word)));
    if (!matches) return null;

    return this.highlightRanges(node, words);
  }

  private words(text:string):string[] {
    return text
      .toLocaleLowerCase()
      .split(/[^\p{L}\p{N}]+/u)
      .filter((word) => word.length > 0);
  }

  private ancestorLabels(node:HTMLElement):string[] {
    const path = JSON.parse(node.dataset.path ?? '[]') as string[];

    return path.slice(0, -1);
  }

  private highlightRanges(node:HTMLElement, words:string[]):Range[] {
    const ranges:Range[] = [];
    const walker = document.createTreeWalker(node, NodeFilter.SHOW_TEXT);

    for (let textNode = walker.nextNode(); textNode; textNode = walker.nextNode()) {
      const text = textNode.textContent?.toLocaleLowerCase() ?? '';

      words.forEach((word) => {
        for (let index = text.indexOf(word); index !== -1; index = text.indexOf(word, index + word.length)) {
          const range = new Range();
          range.setStart(textNode, index);
          range.setEnd(textNode, index + word.length);
          ranges.push(range);
        }
      });
    }

    return ranges;
  }
}
