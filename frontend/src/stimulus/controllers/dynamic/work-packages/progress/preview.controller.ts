/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import { debounce, DebouncedFunc } from 'lodash-es';
import { DialogPreviewController } from '../dialog/preview.controller';

export default class PreviewController extends DialogPreviewController {
  private debouncedPreview:DebouncedFunc<(event:Event) => void>;

  connect() {
    this.debouncedPreview = debounce((event:Event) => {
      let field:HTMLInputElement;
      if (event.type === 'blur') {
        field = (event as FocusEvent).relatedTarget as HTMLInputElement;
      } else {
        field = event.target as HTMLInputElement;
      }

      void this.preview(field);
    }, 100);

    super.connect();
  }

  disconnect() {
    this.debouncedPreview.cancel();
    super.disconnect();
  }

  // Must be true to avoid adding the unit to the active input field value while
  // typing a duration or pressing backspace.
  ignoreActiveValueWhenMorphing():boolean {
    return true;
  }

  afterRendering():void {
    // Do nothing;
  }

  markFieldAsTouched(event:{ target:HTMLInputElement }) {
    this.targetFieldName = event.target.name.replace(/^work_package\[([^\]]+)\]$/, '$1');
    this.markTouched(this.targetFieldName);

    if (this.isWorkBasedMode()) {
      this.keepWorkValue();
    }
  }

  private isWorkBasedMode() {
    return this.findValueInput('done_ratio') !== undefined;
  }

  private keepWorkValue() {
    if (this.isInitialValueEmpty('estimated_hours') && !this.isTouched('estimated_hours')) {
      // let work be derived
      return;
    }

    if (this.isBeingEdited('estimated_hours')) {
      this.untouchFieldsWhenWorkIsEdited();
    } else if (this.isBeingEdited('remaining_hours')) {
      this.untouchFieldsWhenRemainingWorkIsEdited();
    } else if (this.isBeingEdited('done_ratio')) {
      this.untouchFieldsWhenPercentCompleteIsEdited();
    }
  }

  private untouchFieldsWhenWorkIsEdited() {
    if (this.areBothTouched('remaining_hours', 'done_ratio')) {
      if (this.isValueEmpty('done_ratio') && this.isValueEmpty('remaining_hours')) {
        return;
      }
      if (this.isValueEmpty('done_ratio')) {
        this.markUntouched('done_ratio');
      } else {
        this.markUntouched('remaining_hours');
      }
    } else if (this.isTouchedAndEmpty('remaining_hours') && this.isValueSet('done_ratio')) {
      // force remaining work derivation
      this.markUntouched('remaining_hours');
      this.markTouched('done_ratio');
    } else if (this.isTouchedAndEmpty('done_ratio') && this.isValueSet('remaining_hours')) {
      // force % complete derivation
      this.markUntouched('done_ratio');
      this.markTouched('remaining_hours');
    }
  }

  private untouchFieldsWhenRemainingWorkIsEdited() {
    if (this.isTouchedAndEmpty('estimated_hours') && this.isValueSet('done_ratio')) {
      // force work derivation
      this.markUntouched('estimated_hours');
      this.markTouched('done_ratio');
    } else if (this.isValueSet('estimated_hours')) {
      this.markUntouched('done_ratio');
    }
  }

  private untouchFieldsWhenPercentCompleteIsEdited() {
    if (this.isValueSet('estimated_hours')) {
      this.markUntouched('remaining_hours');
    }
  }
}
