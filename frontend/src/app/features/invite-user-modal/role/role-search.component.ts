import {
  Component,
  ElementRef,
  Input,
  OnInit,
} from '@angular/core';
import { UntypedFormControl } from '@angular/forms';
import {
  combineLatest,
  Observable,
  Subject,
} from 'rxjs';
import {
  debounceTime,
  distinctUntilChanged,
  filter,
  map,
} from 'rxjs/operators';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';

/* eslint-disable-next-line change-detection-strategy/on-push */
@Component({
  selector: 'op-ium-role-search',
  templateUrl: './role-search.component.html',
})
export class RoleSearchComponent extends UntilDestroyedMixin implements OnInit {
  @Input() spotFormBinding:UntypedFormControl;

  public input$ = new Subject<string|null>();

  public roles$ = new Subject<any[]>();

  public items$:Observable<any[]>;

  public text = {
    noRolesFound: this.I18n.t('js.invite_user_modal.role.no_roles_found'),
  };

  constructor(
    readonly I18n:I18nService,
    readonly elementRef:ElementRef,
    readonly apiV3Service:ApiV3Service,
  ) {
    super();

    this.items$ = combineLatest(
      this.input$
        .pipe(
          this.untilDestroyed(),
          debounceTime(200),
          filter((input) => typeof input === 'string'),
          map((input:string) => input.toLowerCase()),
          distinctUntilChanged(),
        ),
      this.roles$,
    ).pipe(
      map(([input, roles]:[string, any[]]) => roles.filter((role) => !input || role.name.toLowerCase().indexOf(input) !== -1)),
    );
  }

  ngOnInit():void {
    const filters = new ApiV3FilterBuilder();
    filters.add('grantable', '=', true);
    filters.add('unit', '=', ['project']);
    this.apiV3Service.roles.filtered(filters).get().subscribe(({ elements }) => this.roles$.next(elements));

    setTimeout(() => this.input$.next(''));
  }
}
