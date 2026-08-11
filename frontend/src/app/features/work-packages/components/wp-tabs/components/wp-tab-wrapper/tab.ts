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

import { Component, Injector, Type } from '@angular/core';
import { Observable } from 'rxjs';
import { StateService } from '@uirouter/angular';
import { TabDefinition } from 'core-app/shared/components/tabs/tab.interface';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';

export interface TabComponent extends Component {
  workPackage:WorkPackageResource;
}

export interface WpTabDefinition extends TabDefinition {
  component:Type<TabComponent>;
  displayable?:(workPackage:WorkPackageResource, $state:StateService|null) => boolean;
  count?:(workPackage:WorkPackageResource, injector:Injector) => Observable<number>;
  showCountAsBubble?:boolean;
}
