import {
  Component,
  OnInit,
  Input,
  ElementRef,
} from '@angular/core';
import {FormControl} from "@angular/forms";
import {Observable, Subject, combineLatest} from "rxjs";
import {debounceTime, distinctUntilChanged, filter, map, switchMap, tap} from "rxjs/operators";
import {APIV3Service} from "core-app/modules/apiv3/api-v3.service";
import {ApiV3FilterBuilder} from "core-components/api/api-v3/api-v3-filter-builder";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";

@Component({
  selector: 'op-ium-role-search',
  templateUrl: './role-search.component.html',
})
export class RoleSearchComponent extends UntilDestroyedMixin implements OnInit {
  @Input() roleControl:FormControl;

  public input$ = new Subject<string|null>();
  public roles$ = new Subject<any[]>();
  public items$:Observable<any[]>;

  constructor(
    readonly I18n:I18nService,
    readonly elementRef:ElementRef,
    readonly apiV3Service:APIV3Service,
  ) {
    super();

    this.items$ = combineLatest(
      this.input$
        .pipe(
          this.untilDestroyed(),
          debounceTime(200),
          filter((searchTerm:string) => !!searchTerm),
          map((input:string) => input.toLowerCase()),
          distinctUntilChanged(),
        ),
      this.roles$,
    ).pipe(
      tap(console.log),
      map(([input, roles]:[string, any[]]) => roles.filter((role) => role.name.toLowerCase().indexOf(input) !== -1))
    );
  }

  ngOnInit() {
    const filters = new ApiV3FilterBuilder();
    filters.add('grantable', '=', true);
    filters.add('unit', '=', ['project']);
    console.log('send out roles request');
    this.apiV3Service.roles.filtered(filters).get().subscribe(({ elements }) => this.roles$.next(elements));
  }
}
