import {
  Component, ElementRef, Input,
} from '@angular/core';
import { DatasetInputs } from 'core-app/shared/components/dataset-inputs.decorator';

export const wpTableEntrySelector = 'wp-embedded-table-entry';

@DatasetInputs
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
  }
}
