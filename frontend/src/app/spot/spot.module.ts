import { NgModule } from '@angular/core';
import {
  FormsModule,
  ReactiveFormsModule,
} from '@angular/forms';
import { CommonModule } from '@angular/common';
import { UIRouterModule } from '@uirouter/angular';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { SPOT_DOCS_ROUTES } from './spot.routes';
import { SpotCheckboxComponent } from './components/checkbox/checkbox.component';
import { SpotSwitchComponent } from './components/switch/switch.component';
import { SpotToggleComponent } from './components/toggle/toggle.component';
import { SpotTextFieldComponent } from './components/text-field/text-field.component';
import { SpotFilterChipComponent } from './components/filter-chip/filter-chip.component';
import { SpotDropModalComponent } from './components/drop-modal/drop-modal.component';
import { SpotTooltipComponent } from './components/tooltip/tooltip.component';
import { SpotFormFieldComponent } from './components/form-field/form-field.component';
import { SpotFormBindingDirective } from './components/form-field/form-binding.directive';
import { SpotDocsComponent } from './spot-docs.component';
import { SpotSelectorFieldComponent } from 'core-app/spot/components/selector-field/selector-field.component';
import { AttributeHelpTextModule } from 'core-app/shared/components/attribute-help-texts/attribute-help-text.module';

@NgModule({
  imports: [
    // Routes for /spot-docs
    UIRouterModule.forChild({ states: SPOT_DOCS_ROUTES }),
    FormsModule,
    ReactiveFormsModule,
    CommonModule,
  ],

  providers: [
    I18nService,
  ],

  declarations: [
    SpotDocsComponent,

    SpotCheckboxComponent,
    SpotSwitchComponent,
    SpotToggleComponent,
    SpotTextFieldComponent,
    SpotFilterChipComponent,
    SpotDropModalComponent,
    SpotFormFieldComponent,
    SpotFormBindingDirective,
    SpotTooltipComponent,
    SpotSelectorFieldComponent,
  ],

  exports: [
    SpotCheckboxComponent,
    SpotSwitchComponent,
    SpotToggleComponent,
    SpotTextFieldComponent,
    SpotFilterChipComponent,
    SpotDropModalComponent,
    SpotFormFieldComponent,
    SpotFormBindingDirective,
    SpotTooltipComponent,
    SpotSelectorFieldComponent,
  ],
})
export class OpSpotModule { }
