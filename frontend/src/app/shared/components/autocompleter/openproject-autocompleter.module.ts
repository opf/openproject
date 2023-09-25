import { Injector, NgModule } from '@angular/core';
import { NgSelectModule } from '@ng-select/ng-select';
import {
  FormsModule,
  ReactiveFormsModule,
} from '@angular/forms';
import { DynamicModule } from 'ng-dynamic-component';
import { CommonModule } from '@angular/common';
import { DragulaModule } from 'ng2-dragula';

import { InviteUserButtonModule } from 'core-app/features/invite-user-modal/button/invite-user-button.module';
import { OpenprojectPrincipalRenderingModule } from 'core-app/shared/components/principal/principal-rendering.module';

import { DraggableAutocompleteComponent } from 'core-app/shared/components/autocompleter/draggable-autocomplete/draggable-autocomplete.component';
import { ColorsAutocompleterComponent } from 'core-app/shared/components/colors/colors-autocompleter.component';
import { WorkPackageAutocompleterComponent } from 'core-app/shared/components/autocompleter/work-package-autocompleter/wp-autocompleter.component';
import { TimeEntryWorkPackageAutocompleterComponent } from 'core-app/shared/components/autocompleter/te-work-package-autocompleter/te-work-package-autocompleter.component';
import { AutocompleteSelectDecorationComponent } from 'core-app/shared/components/autocompleter/autocomplete-select-decoration/autocomplete-select-decoration.component';
import { VersionAutocompleterComponent } from 'core-app/shared/components/autocompleter/version-autocompleter/version-autocompleter.component';
import { UserAutocompleterComponent } from 'core-app/shared/components/autocompleter/user-autocompleter/user-autocompleter.component';
import { ProjectAutocompleterComponent } from 'core-app/shared/components/autocompleter/project-autocompleter/project-autocompleter.component';
import { OpAutocompleterComponent } from 'core-app/shared/components/autocompleter/op-autocompleter/op-autocompleter.component';
import { OpAutocompleterOptionTemplateDirective } from 'core-app/shared/components/autocompleter/op-autocompleter/directives/op-autocompleter-option-template.directive';
import { OpAutocompleterLabelTemplateDirective } from 'core-app/shared/components/autocompleter/op-autocompleter/directives/op-autocompleter-label-template.directive';
import { OpAutocompleterHeaderTemplateDirective } from 'core-app/shared/components/autocompleter/op-autocompleter/directives/op-autocompleter-header-template.directive';
import { CreateAutocompleterComponent } from 'core-app/shared/components/autocompleter/create-autocompleter/create-autocompleter.component';
import { OpAutocompleterFooterTemplateDirective } from 'core-app/shared/components/autocompleter/autocompleter-footer-template/op-autocompleter-footer-template.directive';
import { OpSearchHighlightDirective } from 'core-app/shared/directives/search-highlight.directive';
import { registerCustomElement } from 'core-app/shared/helpers/angular/custom-elements.helper';

export const OPENPROJECT_AUTOCOMPLETE_COMPONENTS = [
  CreateAutocompleterComponent,
  VersionAutocompleterComponent,
  WorkPackageAutocompleterComponent,
  TimeEntryWorkPackageAutocompleterComponent,
  DraggableAutocompleteComponent,
  UserAutocompleterComponent,
  ProjectAutocompleterComponent,
  ColorsAutocompleterComponent,
  AutocompleteSelectDecorationComponent,
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
    DragulaModule,
    FormsModule,
    ReactiveFormsModule,

    DynamicModule,
    OpenprojectPrincipalRenderingModule,
    InviteUserButtonModule,
  ],
  exports: OPENPROJECT_AUTOCOMPLETE_COMPONENTS,
  declarations: OPENPROJECT_AUTOCOMPLETE_COMPONENTS,
})
export class OpenprojectAutocompleterModule {
  constructor(injector:Injector) {
    registerCustomElement('opce-autocompleter', OpAutocompleterComponent, { injector });
  }
}
