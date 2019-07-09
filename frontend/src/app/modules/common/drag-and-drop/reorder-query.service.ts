import {Injectable, Query} from "@angular/core";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {debugLog} from "core-app/helpers/debug_output";
import {States} from "core-components/states.service";
import {WorkPackageNotificationService} from "core-components/wp-edit/wp-notification.service";
import {input} from "reactivestates";
import {QueryOrder, QueryOrderDmService} from "core-app/modules/hal/dm-services/query-order-dm.service";
import {IsolatedQuerySpace} from "core-app/modules/work_packages/query-space/isolated-query-space";
import {take} from "rxjs/operators";
import {ReorderDeltaBuilder} from "core-app/modules/common/drag-and-drop/reorder-delta-builder";

@Injectable()
export class ReorderQueryService {



  constructor(readonly states:States,
              readonly querySpace:IsolatedQuerySpace,
              readonly pathHelper:PathHelperService,
              readonly queryOrderDm:QueryOrderDmService,
              readonly wpNotifications:WorkPackageNotificationService) {
  }



}
