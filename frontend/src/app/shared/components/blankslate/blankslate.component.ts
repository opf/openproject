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

/* eslint-disable @angular-eslint/component-selector */

import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { NgTemplateOutlet } from '@angular/common';
import { DynamicIconDirective } from 'core-app/shared/components/primer/dynamic-icon.directive';
import { DynamicIconName } from 'core-app/shared/components/primer/dynamic-icon-map';

@Component({
  selector: 'blankslate-icon',
  template: '<svg octicon class="octicon blankslate-icon" [icon]="icon()" aria-hidden="true" />',
  imports: [DynamicIconDirective],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class BlankslateIconComponent {
  readonly icon = input.required<DynamicIconName>();
}

export type BlankslateHeadingLevel = 2|3|4|5|6;

@Component({
  selector: 'blankslate-heading',
  templateUrl: './blankslate-heading.component.html',
  imports: [NgTemplateOutlet],
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class BlankslateHeadingComponent {
  readonly level = input<BlankslateHeadingLevel>(3);
}

@Component({
  selector: 'blankslate-description',
  template: '<p class="blankslate-description"><ng-content/></p>',
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
