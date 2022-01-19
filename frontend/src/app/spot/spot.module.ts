import { NgModule } from '@angular/core';
import { UIRouterModule } from '@uirouter/angular';
import { SPOT_DOCS_ROUTES } from './spot.routes';
import { SpotDocsComponent } from './spot-docs.component';

@NgModule({
  imports: [
    // Routes for /spot-docs
    UIRouterModule.forChild({ states: SPOT_DOCS_ROUTES }),
  ],
  declarations: [
    SpotDocsComponent,
  ],
  exports: [ ],
})
export class OpSpotModule { }
