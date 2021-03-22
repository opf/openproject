import { OnInit, Component, ViewChild } from "@angular/core";
import { NgSelectComponent } from "@ng-select/ng-select";
import { FieldType } from "@ngx-formly/core";

@Component({
  selector: "op-select",
  templateUrl: "./op-select.component.html",
  styleUrls: ["./op-select.component.scss"]
})
export class OpSelectComponent extends FieldType implements OnInit {
  @ViewChild(NgSelectComponent) ngSelectComponent: NgSelectComponent;

  ngOnInit() {
    // TODO: Improve performance
    setTimeout(() => this.ngSelectComponent.open());
    // When it is a typeahead
    //setTimeout(() => this.ngSelectComponent.searchInput.nativeElement.focus(), 1000)
  }
}
