//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import { ConfigurationService } from 'core-app/modules/common/config/configuration.service';
import { Component, OnInit } from "@angular/core";
import {
  FormattableEditFieldComponent,
  formattableFieldTemplate
} from "core-app/modules/fields/edit/field-types/formattable-edit-field.component";
import { InjectField } from "core-app/helpers/angular/inject-field.decorator";

@Component({
  template: formattableFieldTemplate
})
export class WorkPackageCommentFieldComponent extends FormattableEditFieldComponent implements OnInit {
  public isBusy = false;
  public name = 'comment';

  @InjectField() public ConfigurationService:ConfigurationService;

  public get required() {
    return true;
  }

  ngOnInit() {
    super.ngOnInit();
    this.rawValue = this.rawValue || '';
  }
}
