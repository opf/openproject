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

import { OnDestroyMixin, untilComponentDestroyed } from '@w11k/ngx-componentdestroyed';
import { Directive, OnDestroy } from '@angular/core';
import { Observable } from 'rxjs';

/**
 * Mixin function to provide access to observable and flags
 * whether this component has been destroyed.
 *
 * Use for rxjs with .pipe(this.untilDestroyed)
 */
@Directive()
export class UntilDestroyedMixin extends OnDestroyMixin implements OnDestroy {
  public componentDestroyed = false;

  ngOnDestroy():void {
    this.componentDestroyed = true;
    super.ngOnDestroy();
  }

  /**
   * Helper function to access `untilComponentDestroyed`
   */
  protected untilDestroyed<T>():(source:Observable<T>) => Observable<T> {
    return untilComponentDestroyed(this);
  }
}
