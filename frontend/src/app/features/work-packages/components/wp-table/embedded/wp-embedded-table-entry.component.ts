import {
  Component, ElementRef, Input,
} from '@angular/core';
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
                         [configuration]="configuration">
      </wp-embedded-table>
  `,
})
export class WorkPackageEmbeddedTableEntryComponent {
  @Input() public queryProps:unknown;

  @Input() public configuration:unknown;

  @Input() public initialLoadingIndicator = true;

  constructor(readonly elementRef:ElementRef) {
    populateInputsFromDataset(this);
  }
}
