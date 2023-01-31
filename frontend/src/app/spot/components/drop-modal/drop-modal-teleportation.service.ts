import {
  Injectable,
  TemplateRef,
} from '@angular/core';
import {
  BehaviorSubject,
  Subject,
} from 'rxjs';
import { distinctUntilChanged } from 'rxjs/operators';

export type TeleportInstance = TemplateRef<any>;

@Injectable({ providedIn: 'root' })
export class SpotDropModalTeleportationService extends BehaviorSubject<TeleportInstance|null> {

  public hasRendered$ = new Subject<boolean>();

  public hasRenderedFiltered$ = this.hasRendered$.pipe(distinctUntilChanged());

  constructor() {
    super(null);
  }

  public activate(instance: TeleportInstance) {
    this.next(instance);
  }

  public clear() { 
    this.next(null);
  }
}
