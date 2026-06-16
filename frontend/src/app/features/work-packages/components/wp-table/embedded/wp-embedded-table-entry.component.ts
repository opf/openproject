import { ChangeDetectionStrategy, Component, ElementRef, Input, inject } from '@angular/core';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';
import {
  WorkPackageIsolatedQuerySpaceDirective,
} from 'core-app/features/work-packages/directives/query-space/wp-isolated-query-space.directive';

export const wpTableEntrySelector = 'wp-embedded-table-entry';

@Component({
  selector: wpTableEntrySelector,
  hostDirectives: [WorkPackageIsolatedQuerySpaceDirective],
  template: `
      <wp-embedded-table [queryProps]="queryProps"
                         [initialLoadingIndicator]="initialLoadingIndicator"
                         [configuration]="configuration" />
  `,
  standalone: false,
  // TODO: This component has been partially migrated to be zoneless-compatible.
  // After testing, this should be updated to ChangeDetectionStrategy.OnPush.
  // eslint-disable-next-line @angular-eslint/prefer-on-push-component-change-detection
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class WorkPackageEmbeddedTableEntryComponent {
  readonly elementRef = inject(ElementRef);

  @Input() public queryProps:unknown;

  @Input() public configuration:unknown;

  @Input() public initialLoadingIndicator = true;

  constructor() {
    populateInputsFromDataset(this);
  }
}
