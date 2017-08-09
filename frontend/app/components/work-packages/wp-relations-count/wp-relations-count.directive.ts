import {wpControllersModule} from '../../../angular-modules';
import {
  RelationsStateValue,
  WorkPackageRelationsService
} from '../../wp-relations/wp-relations.service';
import {scopeDestroyed$, scopedObservable} from '../../../helpers/angular-rx-utils';

export class WorkPackageRelationsCount {
  public wpId:number;
  private count:number = 0;

  constructor(public $scope:ng.IScope,
              public wpRelations:WorkPackageRelationsService) {
    this.wpRelations.require(this.wpId.toString());

    scopedObservable(this.$scope,
      this.wpRelations.state(this.wpId.toString()).values$())
      .subscribe((relations:RelationsStateValue) => this.count = _.size(relations));
  }
}

wpControllersModule.component('wpRelationsCount', {
  templateUrl: '/components/work-packages/wp-relations-count/wp-relations-count.directive.html',
  controller: WorkPackageRelationsCount,
  bindings: {
    wpId: '<'
  }
});
