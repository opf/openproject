import {
  Injectable,
  Injector,
} from '@angular/core';
import {
  filter,
  map,
  tap,
} from 'rxjs/operators';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { TimeEntryResource } from 'core-app/features/hal/resources/time-entry-resource';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';
import {
  BehaviorSubject,
  Observable,
} from 'rxjs';

@Injectable()
export class TimeEntryTimerService {
  public timer$ = new BehaviorSubject<TimeEntryResource|null|undefined>(undefined);

  public activeTimer$ = this.timer$
    .asObservable()
    .pipe(
      filter((item) => item !== undefined),
    ) as Observable<TimeEntryResource|null>;

  constructor(
    readonly injector:Injector,
    readonly apiV3Service:ApiV3Service,
  ) {
    // Refresh the timer after some interval to not block other resources
    setTimeout(() => this.refresh().subscribe(), 100);

    this
      .activeTimer$
      .subscribe((entry) => {
        this.removeTimer();

        if (entry) {
          this.renderTimer();
        }
      });
  }

  public refresh():Observable<TimeEntryResource|null> {
    const filters = new ApiV3FilterBuilder();
    filters.add('ongoing', '=', true);

    return this
      .apiV3Service
      .time_entries
      .filtered(filters)
      .get()
      .pipe(
        map((collection) => collection.elements.pop() || null),
        tap((active) => this.timer$.next(active)),
      );
  }

  private renderTimer() {
    const timerElement = document.createElement('span');
    const icon = document.createElement('span');
    timerElement.classList.add('op-principal--timer');
    icon.classList.add('spot-icon', 'spot-icon_time', 'spot-icon_1_25');
    timerElement.appendChild(icon);

    const avatar = document.querySelector<HTMLElement>('.op-top-menu-user-avatar');
    avatar?.appendChild(timerElement);
  }

  private removeTimer() {
    const timerElement = document.querySelector('.op-principal--timer') as HTMLElement;
    timerElement?.remove();
  }
}
