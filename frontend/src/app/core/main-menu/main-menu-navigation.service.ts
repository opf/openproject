import { BehaviorSubject } from 'rxjs';
import { filter, take } from 'rxjs/operators';
import { Injectable } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class MainMenuNavigationService {
  public navigationEvents$ = new BehaviorSubject<string>('');

  public onActivate(...names:string[]) {
    return this
      .navigationEvents$
      .pipe(
        filter((evt) => names.indexOf(evt) !== -1),
        take(1),
      );
  }
}
