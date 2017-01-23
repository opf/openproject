import {injectorBridge} from '../../../angular/angular-injector-bridge.functions';
import {WorkPackageTable} from '../../wp-fast-table';
import {WorkPackageResource} from '../../../api/api-v3/hal-resources/work-package-resource.service';
import {TableEventHandler} from '../table-events-registry';
import {detailsLinkClassName} from '../../builders/details-link-builder';
import {KeepTabService} from '../../../wp-panels/keep-tab/keep-tab.service';

export class DetailsLinkClickHandler implements TableEventHandler {
  // Injections
  public $state:ng.ui.IStateService;
  public keepTab:KeepTabService;

  constructor() {
    injectorBridge(this);
  }

  public get EVENT() {
    return 'click.table.detailsLink';
  }

  public get SELECTOR() {
    return `.${detailsLinkClassName}`;
  }

  protected workPackage:WorkPackageResource;

  public handleEvent(table: WorkPackageTable, evt:JQueryEventObject) {
    console.log('DETAILS BUTTON CLICK!');

    // Locate the row from event
    let target = jQuery(evt.target);
    let element = target.closest(this.SELECTOR);
    let workPackageId = element.data('workPackageId');

    this.$state.go(
      this.keepTab.currentDetailsState,
      { workPackageId: workPackageId }
    );

    evt.preventDefault();
    evt.stopPropagation();
  }
}

DetailsLinkClickHandler.$inject = ['$state', 'keepTab'];
