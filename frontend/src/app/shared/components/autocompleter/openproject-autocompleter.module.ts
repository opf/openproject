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

import { NgModule } from '@angular/core';
import { NgSelectModule } from '@ng-select/ng-select';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { DynamicModule } from 'ng-dynamic-component';
import { CommonModule } from '@angular/common';

import { InviteUserButtonModule } from 'core-app/features/invite-user-modal/button/invite-user-button.module';
import { OpenprojectPrincipalRenderingModule } from 'core-app/shared/components/principal/principal-rendering.module';

import {
  DraggableAutocompleteComponent,
} from 'core-app/shared/components/autocompleter/draggable-autocomplete/draggable-autocomplete.component';
import { ColorsAutocompleterComponent } from 'core-app/shared/components/colors/colors-autocompleter.component';
import {
  WorkPackageAutocompleterComponent,
} from 'core-app/shared/components/autocompleter/work-package-autocompleter/wp-autocompleter.component';
import {
  VersionAutocompleterComponent,
} from 'core-app/shared/components/autocompleter/version-autocompleter/version-autocompleter.component';
import {
  UserAutocompleterComponent,
} from 'core-app/shared/components/autocompleter/user-autocompleter/user-autocompleter.component';
import {
  MeetingAutocompleterComponent,
} from 'core-app/shared/components/autocompleter/meeting-autocompleter/meeting-autocompleter.component';
import {
  ProjectAutocompleterComponent,
} from 'core-app/shared/components/autocompleter/project-autocompleter/project-autocompleter.component';
import {
  OpAutocompleterComponent,
} from 'core-app/shared/components/autocompleter/op-autocompleter/op-autocompleter.component';
import {
  OpAutocompleterOptionTemplateDirective,
} from 'core-app/shared/components/autocompleter/op-autocompleter/directives/op-autocompleter-option-template.directive';
import {
  OpAutocompleterLabelTemplateDirective,
} from 'core-app/shared/components/autocompleter/op-autocompleter/directives/op-autocompleter-label-template.directive';
import {
  OpAutocompleterHeaderTemplateDirective,
} from 'core-app/shared/components/autocompleter/op-autocompleter/directives/op-autocompleter-header-template.directive';
import {
  CreateAutocompleterComponent,
} from 'core-app/shared/components/autocompleter/create-autocompleter/create-autocompleter.component';
import {
  OpAutocompleterFooterTemplateDirective,
} from 'core-app/shared/components/autocompleter/autocompleter-footer-template/op-autocompleter-footer-template.directive';
import { OpSearchHighlightDirective } from 'core-app/shared/directives/search-highlight.directive';
import { OpSortableListsDirective } from 'core-app/shared/directives/sortable-lists/sortable-lists.directive';
import {
  OpSortableListsItemDirective,
} from 'core-app/shared/directives/sortable-lists/sortable-lists-item.directive';
import {
  UserAutocompleterTemplateComponent,
} from 'core-app/shared/components/autocompleter/user-autocompleter/user-autocompleter-template.component';
import {
  MeetingAutocompleterTemplateComponent,
} from 'core-app/shared/components/autocompleter/meeting-autocompleter/meeting-autocompleter-template.component';
import {
  ProjectAutocompleterTemplateComponent,
} from 'core-app/shared/components/autocompleter/project-autocompleter/project-autocompleter-template.component';
import {
  TimeEntriesWorkPackageAutocompleterComponent,
} from 'core-app/shared/components/autocompleter/time-entries-work-package-autocompleter/time-entries-work-package-autocompleter.component';
import {
  ProjectPhaseAutocompleterComponent,
} from './project-phase-autocompleter/project-phase-autocompleter.component';
import { IconModule } from 'core-app/shared/components/icon/icon.module';
import { DynamicIconDirective } from 'core-app/shared/components/primer/dynamic-icon.directive';

export const OPENPROJECT_AUTOCOMPLETE_COMPONENTS = [
  CreateAutocompleterComponent,
  VersionAutocompleterComponent,
  WorkPackageAutocompleterComponent,
  TimeEntriesWorkPackageAutocompleterComponent,
  DraggableAutocompleteComponent,
  UserAutocompleterComponent,
  UserAutocompleterTemplateComponent,
  MeetingAutocompleterTemplateComponent,
  MeetingAutocompleterComponent,
  ProjectAutocompleterComponent,
  ProjectAutocompleterTemplateComponent,
  ProjectPhaseAutocompleterComponent,
  ColorsAutocompleterComponent,
  OpAutocompleterComponent,
  OpAutocompleterOptionTemplateDirective,
  OpAutocompleterLabelTemplateDirective,
  OpAutocompleterHeaderTemplateDirective,
  OpAutocompleterFooterTemplateDirective,
  OpSearchHighlightDirective,
];

@NgModule({
  imports: [
    CommonModule,
    NgSelectModule,
    FormsModule,
    ReactiveFormsModule,

    DynamicModule,
    OpenprojectPrincipalRenderingModule,
    InviteUserButtonModule,
    IconModule,
    DynamicIconDirective,

    OpSortableListsDirective,
    OpSortableListsItemDirective,
  ],
  exports: OPENPROJECT_AUTOCOMPLETE_COMPONENTS,
  declarations: OPENPROJECT_AUTOCOMPLETE_COMPONENTS,
})
export class OpenprojectAutocompleterModule {}
