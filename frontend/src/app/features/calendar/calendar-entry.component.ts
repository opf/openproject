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

import { ChangeDetectionStrategy, Component, ElementRef, Input, OnDestroy, inject } from '@angular/core';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';
import {
  WorkPackageIsolatedQuerySpaceDirective,
} from 'core-app/features/work-packages/directives/query-space/wp-isolated-query-space.directive';

@Component({
  hostDirectives: [WorkPackageIsolatedQuerySpaceDirective],
  template: '<op-wp-calendar-page [queryId]="queryId"><op-wp-calendar /></op-wp-calendar-page>',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class CalendarEntryComponent implements OnDestroy {
  readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);

  @Input() queryId:string;

  constructor() {
    populateInputsFromDataset(this);
    document.body.classList.add('router--calendar');
  }

  ngOnDestroy() {
    document.body.classList.add('router--calendar');
  }
}
