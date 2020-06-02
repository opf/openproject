import {Injectable} from '@angular/core';
import {GridResource} from "core-app/modules/hal/resources/grid-resource";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";
import {GridDmService} from "core-app/modules/hal/dm-services/grid-dm.service";

@Injectable()
export class GridInitializationService {
  constructor(readonly gridDm:GridDmService,
              readonly halResourceService:HalResourceService) {}

  // If a page with the current page exists (scoped to the current user by the backend)
  // that page will be used to initialized the grid.
  // If it does not exist, fetch the form and then create a new resource.
  // The created resource is then used to initialize the grid.
  public initialize(path:string) {
    return this
      .gridDm
      .list({ filters: [['scope', '=', [path]]] })
      .then(collection => {
        if (collection.total === 0) {
          return this.myPageForm(path);
        } else {
          return (collection.elements[0] as GridResource);
        }
      });
  }

  private myPageForm(path:string):Promise<GridResource> {
    return new Promise<GridResource>((resolve, reject) => {
      let payload = {
        '_links': {
          'scope': {
            'href': path
          }
        }
      };

      this
        .gridDm
        .createForm(payload)
        .then((form) => {
          let source = form.payload.$source;

          let resource = this.halResourceService.createHalResource(source) as GridResource;

          if (resource.widgets.length === 0) {
            resource.rowCount = 1;
            resource.columnCount = 1;
          }

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
