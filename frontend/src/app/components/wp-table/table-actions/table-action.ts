import { Injector } from '@angular/core';
import { I18nService } from 'core-app/modules/common/i18n/i18n.service';
import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import { InjectField } from "core-app/helpers/angular/inject-field.decorator";

export type OpTableActionFactory = (i:Injector, wp:WorkPackageResource) => OpTableAction;
export const contextMenuTdClassName = 'wp-table--context-menu-td';
export const contextMenuSpanClassName = 'wp-table--context-menu-span';
export const contextMenuLinkClassName = 'wp-table-context-menu-link';
export const contextColumnIcon = 'wp-table-context-menu-icon';

export abstract class OpTableAction {

  @InjectField() I18n!:I18nService;

  constructor(readonly injector:Injector,
              readonly workPackage:WorkPackageResource) {
  }

  /** Identifier to uniquely identify the action */
  public abstract readonly identifier:string;

  /** The actual action factory to return the action element, if it can be rendered */
  public abstract buildElement():HTMLElement|null;
}
