import {NgModule} from "@angular/core";
import {OpModalService} from "./modal.service";
import {OpModalHeadingComponent} from "./modal-heading.component";

@NgModule({
  imports: [],
  exports: [
    OpModalHeadingComponent,
  ],
  providers: [
    OpModalService,
  ],
  declarations: [
    OpModalHeadingComponent,
  ]
})
export class OpenprojectModalModule { }
