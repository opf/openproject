import {Component, OnInit} from "@angular/core";
import {GridDmService} from "core-app/modules/hal/dm-services/grid-dm.service";
import {GridResource} from "core-app/modules/hal/resources/grid-resource";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

@Component({
  templateUrl: './my-page.component.html'
})
export class MyPageComponent implements OnInit {
  public text = { title: this.i18n.t('js.label_my_page') };

  constructor(readonly gridDm:GridDmService,
              readonly pathHelper:PathHelperService,
              readonly halResourceService:HalResourceService,
              readonly i18n:I18nService) {}

  public grid:GridResource;

  ngOnInit() {
    this
      .loadMyPage()
      .then((grid) => {
        this.grid = grid;
      });
  }

  // If a page with the current page exists (scoped to the current user by the backend)
  // that page will be used to initialized the grid.
  // If it does not exist, fetch the form and then create a new resource.
  // The created resource is then used to initialize the grid.
  private loadMyPage():Promise<GridResource> {
    return this
             .gridDm
             .list({ filters: [['page', '=', [this.pathHelper.myPagePath()]]] })
             .then(collection => {
               if (collection.total === 0) {
                 return this.myPageForm();
               } else {
                 return (collection.elements[0] as GridResource);
               }
             });
  }

  private myPageForm():Promise<GridResource> {
    return new Promise<GridResource>((resolve, reject) => {
      let payload = {
        '_links': {
          'page': {
            'href': this.pathHelper.myPagePath()
          }
        }
      };

      this
        .gridDm
        .createForm(payload)
        .then((form) => {
          let source = form.payload.$source;

          let resource = this.halResourceService.createHalResource(source) as GridResource;

          this.gridDm.create(resource, form.schema)
            .then((resource) => {
              resolve(resource);
            })
            .catch(() => {
              reject();
            });
        });
    });
  }
}
