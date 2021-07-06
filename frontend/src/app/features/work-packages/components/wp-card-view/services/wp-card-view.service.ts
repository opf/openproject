import { Injectable } from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';

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
      workPackages.map((wp) => ({
        classIdentifier: this.classIdentifier(wp),
        workPackageId: wp.id,
        hidden: false,
      })),
    );
  }
}
