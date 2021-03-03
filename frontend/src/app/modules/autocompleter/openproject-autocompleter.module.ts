import { NgModule } from "@angular/core";
import { OpenprojectModalModule } from "core-app/modules/modal/modal.module";
import { NgSelectModule } from "@ng-select/ng-select";
import { OpenprojectCommonModule } from "core-app/modules/common/openproject-common.module";
import { CreateAutocompleterComponent } from "core-app/modules/autocompleter/create-autocompleter/create-autocompleter.component.ts";
import { DraggableAutocompleteComponent } from "core-app/modules/common/draggable-autocomplete/draggable-autocomplete.component";
import { DynamicModule } from "ng-dynamic-component";
import { ColorsAutocompleter } from "core-app/modules/common/colors/colors-autocompleter.component";
import { WorkPackageAutocompleterComponent } from "core-app/modules/autocompleter/work-package-autocompleter/wp-autocompleter.component";
import { TimeEntryWorkPackageAutocompleterComponent } from "core-app/modules/autocompleter/te-work-package-autocompleter/te-work-package-autocompleter.component";
import { AutocompleteSelectDecorationComponent } from "core-app/modules/autocompleter/autocomplete-select-decoration/autocomplete-select-decoration.component";
import { VersionAutocompleterComponent } from "core-app/modules/autocompleter/version-autocompleter/version-autocompleter.component";
import { UserAutocompleterComponent } from "core-app/modules/autocompleter/user-autocompleter/user-autocompleter.component";
import { CommonModule } from "@angular/common";
import { OpenprojectInviteUserModalModule } from "core-app/modules/invite-user-modal/invite-user-modal.module";
import { DragulaModule } from "ng2-dragula";

export const OPENPROJECT_AUTOCOMPLETE_COMPONENTS = [
  CreateAutocompleterComponent,
  VersionAutocompleterComponent,
  WorkPackageAutocompleterComponent,
  TimeEntryWorkPackageAutocompleterComponent,
  DraggableAutocompleteComponent,
  UserAutocompleterComponent,
  ColorsAutocompleter,
  AutocompleteSelectDecorationComponent,
];

@NgModule({
  imports: [
    CommonModule,
    OpenprojectCommonModule,
    OpenprojectModalModule,
    OpenprojectInviteUserModalModule,
    NgSelectModule,
    DragulaModule,

    DynamicModule.withComponents(OPENPROJECT_AUTOCOMPLETE_COMPONENTS)
  ],
  exports: OPENPROJECT_AUTOCOMPLETE_COMPONENTS,
  declarations: OPENPROJECT_AUTOCOMPLETE_COMPONENTS
})
export class OpenprojectAutocompleterModule { }
