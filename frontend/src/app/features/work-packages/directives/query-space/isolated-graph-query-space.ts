import { Injectable } from '@angular/core';
import { input } from '@openproject/reactivestates';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';

@Injectable()
export class IsolatedGraphQuerySpace extends IsolatedQuerySpace {
  chartType = input<string>();
}
