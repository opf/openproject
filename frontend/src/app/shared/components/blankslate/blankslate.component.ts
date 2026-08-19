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

/* eslint-disable @angular-eslint/component-selector */

import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { DynamicIconDirective } from 'core-app/shared/components/primer/dynamic-icon.directive';

@Component({
  selector: 'blankslate-icon',
  template: '<svg octicon [icon]="icon()" />',
  imports: [DynamicIconDirective],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class BlankslateIconComponent {
  readonly icon = input<string>();
}

@Component({
  selector: 'blankslate-heading',
  template: '<h3 class="blankslate-heading"><ng-content/></h3>',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class BlankslateHeadingComponent {
}

@Component({
  selector: 'blankslate-description',
  template: '<p><ng-content/></p>',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class BlankslateDescriptionComponent {
}

@Component({
  selector: 'blankslate-action',
  template: '<div class="blankslate-action"><ng-content/></div>',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class BlankslateActionComponent {
}

@Component({
  selector: 'blankslate',
  templateUrl: './blankslate.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class BlankslateComponent {
}
