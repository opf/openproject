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

import { Directive, forwardRef, Input } from '@angular/core';
import {
  UntypedFormArray, UntypedFormControl, UntypedFormGroup, NgControl,
} from '@angular/forms';

export const formControlBinding = {
  provide: NgControl,
  useExisting: forwardRef(() => SpotFormBindingDirective),
};

@Directive({
  // eslint-disable-next-line @angular-eslint/directive-selector
  selector: '[spotFormBinding]',
  providers: [formControlBinding],
  exportAs: 'ngForm',
  standalone: false,
})
export class SpotFormBindingDirective extends NgControl {
  @Input('spotFormBinding') form!:UntypedFormControl|UntypedFormGroup|UntypedFormArray;

  constructor() {
    super();
  }

  get control():UntypedFormControl|UntypedFormGroup|UntypedFormArray {
    return this.form;
  }

  viewToModelUpdate():void {}
}
