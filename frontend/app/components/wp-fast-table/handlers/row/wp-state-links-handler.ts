import {injectorBridge} from '../../../angular/angular-injector-bridge.functions';
import {WorkPackageTable} from '../../wp-fast-table';
import {WorkPackageResource} from '../../../api/api-v3/hal-resources/work-package-resource.service';
import {TableEventHandler} from '../table-events-registry';
import {KeepTabService} from '../../../wp-panels/keep-tab/keep-tab.service';
import {uiStateLinkClass} from '../../builders/ui-state-link-builder';

export class WorkPackageStateLinksHandler implements TableEventHandler {
  // Injections
  public $state:ng.ui.IStateService;
  public keepTab:KeepTabService;

  constructor() {
    injectorBridge(this);
  }

  public get EVENT() {
    return 'click.table.wpLink';
  }

  public get SELECTOR() {
    return `.${uiStateLinkClass}`;
  }

  protected workPackage:WorkPackageResource;

  public handleEvent(table: WorkPackageTable, evt:JQueryEventObject) {
    console.log('WP STATE LINK CLICK!');

    // Locate the row from event
    let target = jQuery(evt.target);
    let element = target.closest(this.SELECTOR);
    let state = element.data('wpState');
    let workPackageId = element.data('workPackageId');

    this.$state.go(
      this.keepTab[state],
      { workPackageId: workPackageId }
    );

    evt.preventDefault();
    evt.stopPropagation();
  }
}

WorkPackageStateLinksHandler.$inject = ['$state', 'keepTab'];
