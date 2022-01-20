import { NgModule } from '@angular/core';
import { UIRouterModule } from '@uirouter/angular';
import { SPOT_DOCS_ROUTES } from './spot.routes';
import { SpotCheckboxComponent } from './components/checkbox.component';
import { SpotDocsComponent } from './spot-docs.component';

@NgModule({
  imports: [
    // Routes for /spot-docs
    UIRouterModule.forChild({ states: SPOT_DOCS_ROUTES }),
  ],
  declarations: [
    SpotDocsComponent,
    SpotCheckboxComponent,
  ],
  exports: [
    SpotCheckboxComponent,
  ],
})
export class OpSpotModule { }
