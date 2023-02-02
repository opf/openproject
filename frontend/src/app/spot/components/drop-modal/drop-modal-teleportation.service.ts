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
export class SpotDropModalTeleportationService {

  public templateRef$ = new BehaviorSubject<TeleportInstance|null>(null);

  public hasRendered$ = new Subject<boolean>();

  public hasRenderedFiltered$ = this.hasRendered$.pipe(distinctUntilChanged());

  public activate(instance: TeleportInstance) {
    this.templateRef$.next(instance);
  }

  public clear() { 
    this.templateRef$.next(null);
  }
}
