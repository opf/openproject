import {Injectable} from '@angular/core';
import {input} from 'reactivestates';
import {ChartType} from 'chart.js';
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";

@Injectable()
export class IsolatedGraphQuerySpace extends IsolatedQuerySpace {
  chartType = input<ChartType>();
}
