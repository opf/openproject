import {
  Component, ElementRef, Input,
} from '@angular/core';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';

export const wpTableEntrySelector = 'wp-embedded-table-entry';

@Component({
  selector: wpTableEntrySelector,
  template: `
    <ng-container wp-isolated-query-space>
      <wp-embedded-table [queryProps]="queryProps"
                         [initialLoadingIndicator]="initialLoadingIndicator"
                         [configuration]="configuration">
      </wp-embedded-table>
    </ng-container>
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
