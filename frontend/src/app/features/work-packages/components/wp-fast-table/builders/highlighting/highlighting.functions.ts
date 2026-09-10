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

// Resources whose color reads as text rather than as a leading dot. Anything not listed
// here gets a dot from `inlineClass`.
const FOREGROUND_PROPERTIES = ['project_phase_definition', 'meeting_status', 'project_status'];

/**
 * Highlighting is split in two: `app/views/highlighting/styles.css.erb` emits a
 * `__hl_<property>_<id>` class per resource carrying nothing but the color as custom
 * properties, and the `__hl_background` / `__hl_foreground` / `__hl_dot` classes in
 * `global_styles/layout/_colors.sass` turn those into styling. Both go on the same element,
 * so every function below returns a space separated pair. Use `classList.add(...cls.split(' '))`
 * when applying one imperatively.
 */
export namespace Highlighting {
  export function resourceClass(property:string, id:string|number) {
    return `__hl_${property}_${id}`;
  }

  export function backgroundClass(property:string, id:string|number) {
    return `__hl_background ${resourceClass(property, id)}`;
  }

  export function foregroundClass(property:string, id:string|number) {
    return `__hl_foreground ${resourceClass(property, id)}`;
  }

  export function dotClass(property:string, id:string|number) {
    return `__hl_dot ${resourceClass(property, id)}`;
  }

  // Work package types are rendered as uppercase bold text instead of getting a dot
  export function typeClass(id:string|number) {
    return `__hl_uppercase ${foregroundClass('type', id)}`;
  }

  /**
   * Picks the treatment for a property that is only known at runtime.
   */
  export function inlineClass(property:string, id:string|number) {
    if (property === 'type') {
      return typeClass(id);
    }

    if (FOREGROUND_PROPERTIES.includes(property)) {
      return foregroundClass(property, id);
    }

    return dotClass(property, id);
  }

  /**
   * Given the difference from today (negative = n days in the past),
   * output the fixed overdue classes
   * @param diff
   */
  export function overdueDate(diff:number):string {
    if (diff === 0) {
      return '__hl_date_due_today';
    }
    // At least one day
    if (diff <= -1) {
      return '__hl_date_overdue';
    }

    return '__hl_date_not_overdue';
  }
}
