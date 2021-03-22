import { IsolatedQuerySpace } from "core-app/modules/work_packages/query-space/isolated-query-space";
import { Injectable } from '@angular/core';
import { WorkPackageResource } from "core-app/modules/hal/resources/work-package-resource";

@Injectable()
export class WorkPackageCardViewService {
  public constructor(readonly querySpace:IsolatedQuerySpace) {
  }

  public classIdentifier(wp:WorkPackageResource) {
    // The same class names are used for the proximity to the table representation.
    return `wp-row-${wp.id}`;
  }

  public get renderedCards() {
    return this.querySpace.tableRendered.getValueOr([]);
  }

  public findRenderedCard(classIdentifier:string):number {
    const index = _.findIndex(this.renderedCards, (card) => card.classIdentifier === classIdentifier);

    return index;
  }

  public updateRenderedCardsValues(workPackages:WorkPackageResource[]) {
    this.querySpace.tableRendered.putValue(
      workPackages.map((wp) => {
        return {
          classIdentifier: this.classIdentifier(wp),
          workPackageId: wp.id,
          hidden: false
        };
      })
    );
  }
}
