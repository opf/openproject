import {NgModule} from "@angular/core";
import {OpModalService} from "./modal.service";
import {OpModalHeaderComponent} from "./modal-header.component";

@NgModule({
  imports: [],
  exports: [
    OpModalHeaderComponent,
  ],
  providers: [
    OpModalService,
  ],
  declarations: [
    OpModalHeaderComponent,
  ]
})
export class OpenprojectModalModule { }
