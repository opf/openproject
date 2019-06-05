import {Injectable} from '@angular/core';
import {WorkPackageTableHighlightingService} from "core-components/wp-fast-table/state/wp-table-highlighting.service";


@Injectable()
export class WorkPackageInlineHighlightingService extends WorkPackageTableHighlightingService {

  public get isInline() {
    return true;
  }

  public get isDisabled() {
    return false;
  }
}
