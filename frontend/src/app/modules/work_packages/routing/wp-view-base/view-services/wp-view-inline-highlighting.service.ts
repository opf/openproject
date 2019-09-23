import {Injectable} from '@angular/core';
import {WorkPackageViewHighlightingService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-highlighting.service";


@Injectable()
export class WorkPackageInlineHighlightingService extends WorkPackageViewHighlightingService {

  public get isInline() {
    return true;
  }

  public get isDisabled() {
    return false;
  }
}
