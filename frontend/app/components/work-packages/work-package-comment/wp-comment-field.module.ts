// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {WikiTextareaEditField} from '../../wp-edit/field-types/wp-edit-wiki-textarea-field.module';
import {WorkPackageChangeset} from '../../wp-edit-form/work-package-changeset';

export class WorkPackageCommentField extends WikiTextareaEditField {
  public _value:any;
  public isBusy:boolean = false;

  constructor(public workPackage:WorkPackageResourceInterface, protected I18n:op.I18n) {
    super(new WorkPackageChangeset(workPackage), 'comment', {name: I18n.t('js.label_comment')} as any);

    this.initializeFieldValue();
  }

  public get value() {
    return this._value;
  }

  public set value(val:any) {
    this._value = val;
  }

  public get required() {
    return true;
  }

  public initializeFieldValue(withText?:string):void {
    if (!withText) {
      this.rawValue = '';
      return;
    }

    if (this.rawValue.length > 0) {
      this.rawValue += '\n';
    }

    this.rawValue += withText;
  }

}
