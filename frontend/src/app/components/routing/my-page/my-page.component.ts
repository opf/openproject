import {Component, OnInit} from "@angular/core";
import {GridDmService} from "core-app/modules/hal/dm-services/grid-dm.service";
import {GridResource} from "core-app/modules/hal/resources/grid-resource";

@Component({
  templateUrl: './my-page.component.html'
})
export class MyPageComponent implements OnInit {
  constructor(readonly gridDm:GridDmService) {}

  public grid:GridResource;

  ngOnInit() {
    this
      .gridDm
      .createForm({})
      .then((form) => {
        this.grid = (form.payload as GridResource);
      });
  }
}
