import { Observable } from 'rxjs';

export interface TabDefinition {
  /** Internal identifier of the tab */
  id:string;
  /** Human readable name */
  name:string;
  /** Manual URL to link to if set */
  path?:string;
  /** UI router route to use uiSref with */
  route?:string;
  /** UI router params to use uiParams with */
  routeParams?:unknown;
  /** Show a tab count with this observable's result */
  counter?:Observable<number>;
  /** Disable the tab, optionally with an explanatory title */
  disable?:string|true;
}
