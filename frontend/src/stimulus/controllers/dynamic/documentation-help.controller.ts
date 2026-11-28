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

export default class DocumentationHelpController extends Controller<HTMLDialogElement> {
  static targets = ['frame', 'expandButton'];
  static values = { indexUrl: String, expandLabel: String, collapseLabel: String };

  declare readonly frameTarget:HTMLElement & { src:string };
  declare readonly expandButtonTarget:HTMLButtonElement;
  declare readonly indexUrlValue:string;
  declare readonly expandLabelValue:string;
  declare readonly collapseLabelValue:string;

  private articleHistory:string[] = [];

  remember(event:MouseEvent):void {
    const target = event.target as HTMLElement;
    if (target.closest('a[data-help-article]') && !event.ctrlKey && !event.metaKey) {
      this.articleHistory.push(this.frameTarget.src);
    }
  }

  back():void {
    this.frameTarget.src = this.articleHistory.pop() ?? this.indexUrlValue;
  }

  jump(event:MouseEvent):void {
    event.preventDefault();
    const link = event.currentTarget as HTMLAnchorElement;
    this.frameTarget.querySelector<HTMLElement>(link.hash)?.scrollIntoView({ block: 'start' });
  }

  toggleExpanded():void {
    const expanded = this.element.classList.toggle('contextual-help-dialog_expanded');
    this.expandButtonTarget.setAttribute('aria-pressed', String(expanded));
    const label = this.expandButtonTarget.querySelector('.Button-label');
    if (label) label.textContent = expanded ? this.collapseLabelValue : this.expandLabelValue;
  }

  articleLoaded():void {
    this.element.querySelector('.Overlay-body')?.scrollTo(0, 0);
    this.frameTarget.querySelector<HTMLElement>('h1')?.focus({ preventScroll: true });
  }
}
