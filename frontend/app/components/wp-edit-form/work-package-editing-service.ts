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

import {States} from '../states.service';
import {wpServicesModule} from '../../angular-modules';
import {WorkPackageEditForm} from './work-package-edit-form';
import {WorkPackageResourceInterface} from '../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageEditContext} from './work-package-edit-context';

export class WorkPackageEditingService {
  constructor(public states:States, public $q:ng.IQService) {
  }

  public startEditing(workPackageId:string, editContext:WorkPackageEditContext, editAll:boolean = false):WorkPackageEditForm {
    const state = this.editState(workPackageId);
    const form = state.getValueOr(new WorkPackageEditForm(workPackageId, editAll));
    form.editContext = editContext;
    form.editMode = editAll;
    state.putValue(form);

    return form;
  }

  public stopEditing(workPackageId:string) {
    const state = this.editState(workPackageId);

    if (state.hasValue()) {
      state.value!.stopEditing();
    }
  }

  public saveChanges(workPackageId:string):ng.IPromise<WorkPackageResourceInterface> {
    const state = this.editState(workPackageId);

    if (state.hasValue()) {
      return state.value!.submit();
    }

    return this.$q.reject();
  }

  public editState(workPackageId:string) {
    return this.states.editing.get(workPackageId);
  }
}

wpServicesModule.service('wpEditing', WorkPackageEditingService)

