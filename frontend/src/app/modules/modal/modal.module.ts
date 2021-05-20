import { NgModule } from "@angular/core";
import { CommonModule } from "@angular/common";
import { FocusModule } from "core-app/modules/focus/focus.module";
import { IconModule } from "core-app/modules/icon/icon.module";
import { OpModalService } from "./modal.service";
import { OpModalWrapperAugmentService } from "./modal-wrapper-augment.service";
import { OpModalHeaderComponent } from "./modal-header.component";

@NgModule({
  imports: [
    CommonModule,
    FocusModule,
    IconModule,
  ],
  exports: [ OpModalHeaderComponent ],
  providers: [
    OpModalService,
    OpModalWrapperAugmentService,
  ],
  declarations: [ OpModalHeaderComponent ]
})
export class OpenprojectModalModule { }
