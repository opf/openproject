import {WorkPackageResourceInterface} from 'core-components/api/api-v3/hal-resources/work-package-resource.service';
import {Injector} from '@angular/core';
import {I18nToken} from 'core-app/angular4-transition-utils';

export type OpTableActionFactory = (i:Injector, wp:WorkPackageResourceInterface) => OpTableAction;

export abstract class OpTableAction {

  public I18n:op.I18n = this.injector.get(I18nToken);

  constructor(readonly injector:Injector,
              readonly workPackage:WorkPackageResourceInterface) {
  }

  /** Identifier to uniquely identify the action */
  public abstract readonly identifier:string;

  /** The actual action factory to return the action element */
  public abstract buildElement():HTMLElement;
}
