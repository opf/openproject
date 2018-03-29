import {Component, Input, OnDestroy, OnInit} from '@angular/core';
import {downgradeComponent} from '@angular/upgrade/static';
import {componentDestroyed} from 'ng2-rx-componentdestroyed';
import {takeUntil} from 'rxjs/operators';
import {wpControllersModule} from '../../../angular-modules';
import {RelationsStateValue, WorkPackageRelationsService} from '../../wp-relations/wp-relations.service';

@Component({
  template: require('!!raw-loader!./wp-relations-count.html'),
  selector: 'wp-relations-count',
})
export class WorkPackageRelationsCountComponent implements OnInit, OnDestroy {
  @Input('wpId') wpId:string;
  public count:number = 0;

  constructor(public wpRelations:WorkPackageRelationsService) {
  }

  ngOnInit():void {
    this.wpRelations.require(this.wpId.toString());

    this.wpRelations.state(this.wpId.toString()).values$()
      .pipe(
        takeUntil(componentDestroyed(this))
      )
      .subscribe((relations:RelationsStateValue) => {
        this.count = _.size(relations);
      });
  }

  ngOnDestroy():void {
    // Nothing to do
  }
}

wpControllersModule.directive(
  'wpRelationsCount',
  downgradeComponent({component: WorkPackageRelationsCountComponent})
);

