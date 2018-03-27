import {
  OpTableAction,
  OpTableActionFactory,
} from 'core-components/wp-table/table-actions/table-action';
import {opIconElement} from 'core-app/helpers/op-icon-builder';
import {contextColumnIcon} from 'core-components/wp-fast-table/builders/table-action-renderer';
import {WorkPackageResourceInterface} from 'core-components/api/api-v3/hal-resources/work-package-resource.service';
import {Injector} from '@angular/core';

export class OpUnlinkTableAction extends OpTableAction {

  constructor(public injector:Injector,
              public workPackage:WorkPackageResourceInterface,
              public readonly identifier:string,
              private title:string,
              readonly onClick:(workPackage:WorkPackageResourceInterface) => void) {
    super(injector, workPackage);

  }

  /**
   *  Returns a factory for this action with the given title and identifier for reusing
   *  remove actions.
   *
   * @param {string} identifier
   * @param {string} title
   */
  public static factoryFor(identifier:string,
                           title:string,
                           onClick:(workPackage:WorkPackageResourceInterface) => void):OpTableActionFactory {
    return (injector:Injector, workPackage:WorkPackageResourceInterface) => {
      return new OpUnlinkTableAction(injector,
        workPackage,
        identifier,
        title,
        onClick) as OpTableAction;
    };
  }

  public buildElement() {
    let element = document.createElement('a');
    element.title = this.title;
    element.href = '#';
    element.classList.add(contextColumnIcon, 'wp-table-action--unlink');
    element.dataset.workPackageId = this.workPackage.id.toString();
    element.appendChild(opIconElement('icon', 'icon-close'));
    jQuery(element).click(() => this.onClick(this.workPackage));

    return element;
  }
}
