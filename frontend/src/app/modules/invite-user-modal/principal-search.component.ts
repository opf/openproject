import {
  Component,
  Input,
  EventEmitter,
  Output,
  ElementRef,
} from '@angular/core';
import {FormControl} from "@angular/forms";
import {Observable, Subject, combineLatest} from "rxjs";
import {debounceTime, distinctUntilChanged, filter, map, tap, switchMap} from "rxjs/operators";
import {APIV3Service} from "core-app/modules/apiv3/api-v3.service";
import {ApiV3FilterBuilder} from "core-components/api/api-v3/api-v3-filter-builder";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";

@Component({
  selector: 'op-ium-principal-search',
  templateUrl: './principal-search.component.html',
})
export class InvitePrincipalSearchComponent extends UntilDestroyedMixin {
  @Input() principalControl:FormControl;
  @Input() type:string;

  public input$ = new Subject<string|null>();
  public items$:Observable<any>;
  public isEmailAndInvitable$:Observable<any>;
  public isCreateablePlaceholder$:Observable<any>;

  constructor(
    readonly I18n:I18nService,
    readonly elementRef:ElementRef,
    readonly apiV3Service:APIV3Service,
  ) {
    super();

    this.items$ = this.input$
      .pipe(
        this.untilDestroyed(),
        debounceTime(200),
        filter((searchTerm:string) => !!searchTerm),
        distinctUntilChanged(),
        switchMap((searchTerm:string) => {
          const filters = new ApiV3FilterBuilder();
          filters.add('name_and_identifier', '~', [searchTerm]);
          return this.apiV3Service.projects.filtered(filters).get().pipe(map(collection => collection.elements));
        }),
      );

    this.isEmailAndInvitable$ = combineLatest(
      this.items$,
      this.input$,
    ).pipe(
      tap(console.log),
      map(([elements, input]) => this.type === 'user' && input.includes('@') && elements.find((el: any) => el.email === input)),
    );

    this.isCreateablePlaceholder$ = this.items$.pipe(map(() => true));
  }
}
