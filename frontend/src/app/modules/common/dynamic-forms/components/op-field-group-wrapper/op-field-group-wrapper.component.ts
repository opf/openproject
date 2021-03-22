import { Component, ViewChild, ViewContainerRef } from "@angular/core";
import { FieldWrapper } from "@ngx-formly/core";

@Component({
  selector: "op-field-group-wrapper",
  templateUrl: "./op-field-group-wrapper.component.html",
  styleUrls: ["./op-field-group-wrapper.component.scss"]
})
export class OpFieldGroupWrapperComponent extends FieldWrapper {
  @ViewChild("fieldComponent", { read: ViewContainerRef })
  fieldComponent: ViewContainerRef;
}
