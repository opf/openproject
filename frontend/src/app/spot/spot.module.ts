import { NgModule } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { UIRouterModule } from '@uirouter/angular';
import { SPOT_DOCS_ROUTES } from './spot.routes';
import { SpotCheckboxComponent } from './components/checkbox/checkbox.component';
import { SpotToggleComponent } from './components/toggle/toggle.component';
import { SpotTextFieldComponent } from './components/text-field/text-field.component';
import { SpotFilterChipComponent } from './components/filter-chip/filter-chip.component';
import { SpotChipFieldComponent } from './components/chip-field/chip-field.component';
import { SpotDropModalComponent } from './components/drop-modal/drop-modal.component';
import { SpotDocsComponent } from './spot-docs.component';

@NgModule({
  imports: [
    // Routes for /spot-docs
    UIRouterModule.forChild({ states: SPOT_DOCS_ROUTES }),
    FormsModule,
    CommonModule,
  ],
  declarations: [
    SpotDocsComponent,

    SpotCheckboxComponent,
    SpotToggleComponent,
    SpotTextFieldComponent,
    SpotFilterChipComponent,
    SpotChipFieldComponent,
    SpotDropModalComponent,
  ],
  exports: [
    SpotCheckboxComponent,
    SpotToggleComponent,
    SpotTextFieldComponent,
    SpotFilterChipComponent,
    SpotChipFieldComponent,
    SpotDropModalComponent,
  ],
})
export class OpSpotModule { }
