import {
  Injectable,
  TemplateRef,
} from '@angular/core';
import {
  BehaviorSubject,
  Subject,
} from 'rxjs';
import { distinctUntilChanged, filter, take } from 'rxjs/operators';

export type TeleportInstance = TemplateRef<any>;

@Injectable({ providedIn: 'root' })
export class SpotDropModalTeleportationService {

  public templateRef$ = new BehaviorSubject<TeleportInstance|null>(null);

  public hasRendered$ = new Subject<boolean>();

  public hasRenderedFiltered$ = this.hasRendered$.pipe(distinctUntilChanged());

  public afterRenderOnce$(appearOrDissapear:boolean = true) {
    return this.hasRenderedFiltered$
      .pipe(
        filter(f => f === appearOrDissapear),
        take(1),
      );
  }

  public activate(instance: TeleportInstance) {
    this.templateRef$.next(instance);
  }

  public clear() { 
    this.templateRef$.next(null);
  }
}
