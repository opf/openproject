import {
  Injectable,
  TemplateRef,
} from '@angular/core';
import { BehaviorSubject, Subject } from 'rxjs';

export type TeleportInstance = TemplateRef<any>;

@Injectable({ providedIn: 'root' })
export class SpotDropModalTeleportationService extends BehaviorSubject<TeleportInstance|null> {

  public hasRendered$ = new Subject();

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
