import { Injectable } from '@angular/core';
import { GridResource } from 'core-app/features/hal/resources/grid-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { APIV3Service } from 'core-app/core/apiv3/api-v3.service';
import { switchMap } from 'rxjs/operators';

@Injectable()
export class GridInitializationService {
  constructor(readonly apiV3Service:APIV3Service,
    readonly halResourceService:HalResourceService) {
  }

  // If a page with the current page exists (scoped to the current user by the backend)
  // that page will be used to initialized the grid.
  // If it does not exist, fetch the form and then create a new resource.
  // The created resource is then used to initialize the grid.
  public initialize(path:string) {
    return this
      .apiV3Service
      .grids
      .list({ filters: [['scope', '=', [path]]] })
      .toPromise()
      .then((collection) => {
        if (collection.total === 0) {
          return this.myPageForm(path);
        }
        return (collection.elements[0]);
      });
  }

  private myPageForm(path:string):Promise<GridResource> {
    const payload = {
      _links: {
        scope: {
          href: path,
        },
      },
    };

    return this
      .apiV3Service
      .grids
      .form
      .post(payload)
      .pipe(
        switchMap((form) => {
          const source = form.payload.$source;
          const resource:GridResource = this.halResourceService.createHalResource(source);

          if (resource.widgets.length === 0) {
            resource.rowCount = 1;
            resource.columnCount = 1;
          }

          return this
            .apiV3Service
            .grids
            .post(resource, form.schema);
        }),
      )
      .toPromise();
  }
}
