import { NgModule } from '@angular/core';
import {
  FormsModule,
  ReactiveFormsModule,
} from '@angular/forms';
import { CommonModule } from '@angular/common';
import { A11yModule } from '@angular/cdk/a11y';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { SpotCheckboxComponent } from './components/checkbox/checkbox.component';
import { SpotSwitchComponent } from './components/switch/switch.component';
import { SpotToggleComponent } from './components/toggle/toggle.component';
import { SpotTextFieldComponent } from './components/text-field/text-field.component';
import { SpotFilterChipComponent } from './components/filter-chip/filter-chip.component';
import { SpotDropModalComponent } from './components/drop-modal/drop-modal.component';
import { SpotTooltipComponent } from './components/tooltip/tooltip.component';
import { SpotFormFieldComponent } from './components/form-field/form-field.component';
import { SpotFormBindingDirective } from './components/form-field/form-binding.directive';
import { SpotBreadcrumbsComponent } from './components/breadcrumbs/breadcrumbs.component';
import { SpotSelectorFieldComponent } from './components/selector-field/selector-field.component';
import { SpotDropModalPortalComponent } from './components/drop-modal/drop-modal-portal.component';

@NgModule({
  imports: [
    FormsModule,
    ReactiveFormsModule,
    CommonModule,
    A11yModule,
  ],

  providers: [
    I18nService,
  ],

  declarations: [
    SpotBreadcrumbsComponent,
    SpotCheckboxComponent,
    SpotSwitchComponent,
    SpotToggleComponent,
    SpotTextFieldComponent,
    SpotFilterChipComponent,
    SpotDropModalComponent,
    SpotDropModalPortalComponent,
    SpotDropModalPortalComponent,
    SpotFormFieldComponent,
    SpotFormBindingDirective,
    SpotTooltipComponent,
    SpotSelectorFieldComponent,
  ],

  exports: [
    SpotBreadcrumbsComponent,
    SpotCheckboxComponent,
    SpotSwitchComponent,
    SpotToggleComponent,
    SpotTextFieldComponent,
    SpotFilterChipComponent,
    SpotDropModalComponent,
    SpotDropModalPortalComponent,
    SpotDropModalPortalComponent,
    SpotFormFieldComponent,
    SpotFormBindingDirective,
    SpotTooltipComponent,
    SpotSelectorFieldComponent,
  ],
})
export class OpSpotModule { }
