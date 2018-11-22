import {Component, OnInit} from "@angular/core";
import {GridDmService} from "core-app/modules/hal/dm-services/grid-dm.service";
import {GridResource} from "core-app/modules/hal/resources/grid-resource";
import {ApiV3FilterBuilder} from "core-components/api/api-v3/api-v3-filter-builder";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {CollectionResource} from "core-app/modules/hal/resources/collection-resource";

@Component({
  templateUrl: './my-page.component.html'
})
export class MyPageComponent implements OnInit {
  constructor(readonly gridDm:GridDmService,
              readonly pathHelper:PathHelperService) {}

  public grid:GridResource;

  ngOnInit() {
    this
      .loadMyPage()
      .then((grid) => {
        this.grid = grid;
      });
  }

  private loadMyPage():Promise<GridResource> {
    return this
             .gridDm
             .list([['page', '=', [this.pathHelper.myPagePath()]]])
             .then(collection => {
               if (collection.total === 0) {
                 return this.myPageForm();
               } else {
                 return (collection.elements[0] as GridResource);
               }
             });
  }

  private myPageForm():Promise<GridResource> {
    let payload = {
      '_links': {
        'page': {
          'href': this.pathHelper.myPagePath()
        }
      }
    };

    return this
      .gridDm
      .createForm(payload)
      .then((form) => {
        return (form.payload as GridResource);
      });
  }
}
