import { Observable } from 'rxjs';
import { Injector } from '@angular/core';

export interface TabDefinition {
  /** Internal identifier of the tab */
  id:string;
  /** Human-readable name */
  name:string;
  /** Manual URL to link to if set */
  path?:string;
  /** UI router route to use uiSref with */
  route?:string;
  /** UI router params to use uiParams with */
  routeParams?:unknown;
  /** Show a tab count with this observable's result */
  counter?:(injector?:Injector) => Observable<number>;
  /** Whether the counter should be shown as number in brackets or within a bubble */
  showCountAsBubble?:boolean;
  /** Disable the tab, optionally with an explanatory title */
  disable?:string|true;
}
