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

import { ChangeDetectorRef, DestroyRef, inject } from '@angular/core';
import { AbstractControl } from '@angular/forms';
import { Subscription } from 'rxjs';

export function observeFormState():(control:AbstractControl|null|undefined, form:AbstractControl|null|undefined) => void {
  const changeDetector = inject(ChangeDetectorRef);
  let control:AbstractControl|null|undefined;
  let form:AbstractControl|null|undefined;
  let subscription = new Subscription();
  inject(DestroyRef).onDestroy(() => subscription.unsubscribe());

  return (nextControl:AbstractControl|null|undefined, nextForm:AbstractControl|null|undefined):void => {
    if (control === nextControl && form === nextForm) return;
    subscription.unsubscribe();
    subscription = new Subscription();
    control = nextControl;
    form = nextForm;
    for (const current of new Set([control, form])) {
      if (current) subscription.add(current.events.subscribe(() => changeDetector.markForCheck()));
    }
    changeDetector.markForCheck();
  };
}
