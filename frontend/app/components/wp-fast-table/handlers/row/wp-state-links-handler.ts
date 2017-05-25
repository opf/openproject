import {injectorBridge} from '../../../angular/angular-injector-bridge.functions';
import {WorkPackageTable} from '../../wp-fast-table';
import {WorkPackageResource} from '../../../api/api-v3/hal-resources/work-package-resource.service';
import {TableEventHandler} from '../table-handler-registry';
import {KeepTabService} from '../../../wp-panels/keep-tab/keep-tab.service';
import {uiStateLinkClass} from '../../builders/ui-state-link-builder';

export class WorkPackageStateLinksHandler implements TableEventHandler {
  // Injections
  public $state:ng.ui.IStateService;
  public keepTab:KeepTabService;

  constructor(table: WorkPackageTable) {
    injectorBridge(this);
  }

  public get EVENT() {
    return 'click.table.wpLink';
  }

  public get SELECTOR() {
    return `.${uiStateLinkClass}`;
  }

  public eventScope(table:WorkPackageTable) {
    return jQuery(table.container);
  }

  protected workPackage:WorkPackageResource;

  public handleEvent(table: WorkPackageTable, evt:JQueryEventObject) {
    // Avoid the state capture when clicking with modifier
    if (evt.shiftKey || evt.ctrlKey || evt.metaKey || evt.altKey) {
      return true;
    }

    // Locate the row from event
    const target = jQuery(evt.target);
    const element = target.closest(this.SELECTOR);
    const state = element.data('wpState');
    const workPackageId = element.data('workPackageId');

    this.$state.go(
      (this.keepTab as any)[state],
      { workPackageId: workPackageId, focus: true }
    );

    evt.preventDefault();
    evt.stopPropagation();
    return false;
  }
}

WorkPackageStateLinksHandler.$inject = ['$state', 'keepTab'];
