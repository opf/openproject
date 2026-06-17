import { ChangeDetectionStrategy, Component, ElementRef, OnDestroy, inject } from '@angular/core';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';
import {
  WorkPackageIsolatedQuerySpaceDirective,
} from 'core-app/features/work-packages/directives/query-space/wp-isolated-query-space.directive';

@Component({
  hostDirectives: [WorkPackageIsolatedQuerySpaceDirective],
  template: '<op-team-planner-page><op-team-planner /></op-team-planner-page>',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class TeamPlannerEntryComponent implements OnDestroy {
  readonly elementRef = inject<ElementRef<HTMLElement>>(ElementRef);

  constructor() {
    populateInputsFromDataset(this);
    document.body.classList.add('router--team-planner');
  }

  ngOnDestroy():void {
    document.body.classList.remove('router--team-planner');
  }
}
