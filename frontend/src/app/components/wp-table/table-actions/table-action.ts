import {Injector} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';

export type OpTableActionFactory = (i:Injector, wp:WorkPackageResource) => OpTableAction;

export abstract class OpTableAction {

  public I18n:I18nService = this.injector.get(I18nService);

  constructor(readonly injector:Injector,
              readonly workPackage:WorkPackageResource) {
  }

  /** Identifier to uniquely identify the action */
  public abstract readonly identifier:string;

  /** The actual action factory to return the action element */
  public abstract buildElement():HTMLElement;
}
