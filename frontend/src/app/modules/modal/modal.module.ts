import {NgModule} from "@angular/core";
import {OpModalService} from "./modal.service";
import {OpModalComponent} from "./modal.component";
import {OpModalHeadingComponent} from "./modal-heading.component";

@NgModule({
  imports: [],
  exports: [
    OpModalComponent,
    OpModalService,
    OpModalHeadingComponent,
  ],
  declarations: [
    OpModalService,
    OpModalComponent,
    OpModalHeadingComponent,
  ]
})
export class OpenprojectModalModule { }
