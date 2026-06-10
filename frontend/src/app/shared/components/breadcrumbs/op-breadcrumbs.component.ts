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

import { ChangeDetectionStrategy, Component, Input, inject } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';

export type BreadcrumbItem =
  | { href:string; text:string }
  | string;

@Component({
  templateUrl: './op-breadcrumbs.component.html',
  selector: 'op-breadcrumbs',
  styleUrls: ['./op-breadcrumbs.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class OpBreadcrumbsComponent {
  readonly I18n = inject(I18nService);

  @Input() items:BreadcrumbItem[] = [];
  @Input() lastItemSection?:string | null = null;

  text = {
    breadcrumb: this.I18n.t('js.breadcrumb'),
  };

  isLink(item:BreadcrumbItem):item is { href:string; text:string } {
    return typeof item !== 'string' && 'href' in item && 'text' in item;
  }

  getText(item:BreadcrumbItem):string {
    if (this.isLink(item)) {
      return item.text;
    }
    if (typeof item === 'string') {
      return item;
    }
    return '';
  }

  getHref(item:BreadcrumbItem):string | null {
    return this.isLink(item) ? item.href : null;
  }

  trackBreadcrumbItem(index:number, item:BreadcrumbItem):string {
    if (this.isLink(item)) {
      return `link:${item.href}:${index}`;
    }

    return `text:${item}:${index}`;
  }
}
