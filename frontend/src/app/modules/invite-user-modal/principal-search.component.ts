import {
  Component,
  Input,
  EventEmitter,
  Output,
  ElementRef,
} from '@angular/core';
import {FormControl} from "@angular/forms";
import {Observable, BehaviorSubject, combineLatest} from "rxjs";
import {debounceTime, distinctUntilChanged, first, filter, map, tap, switchMap} from "rxjs/operators";
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

  @Output() createNew = new EventEmitter<string>();

  public input$ = new BehaviorSubject('');
  public items$:Observable<any>;
  public canInviteByEmail$:Observable<any>;
  public canCreateNewGroupOrPlaceholder$:Observable<any>;

  private get api() {
    return {
      'user': this.apiV3Service.users,
      'group': this.apiV3Service.groups,
      'placeholder': this.apiV3Service.placeholders,
    }[this.type];
  }

  constructor(
    public I18n:I18nService,
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
          filters.add('name', '~', [searchTerm]);
          return this.api.filtered(filters).get().pipe(map(collection => collection.elements));
        }),
      );

    this.canInviteByEmail$ = combineLatest(
      this.items$,
      this.input$,
    ).pipe(
      tap(console.log),
      map(([elements, input]) => this.type === 'user' && input?.includes('@') && !elements.find((el:any) => el.email === input)),
    );

    this.canCreateNewGroupOrPlaceholder$ = combineLatest(
      this.items$,
      this.input$,
    ).pipe(
      tap(console.log),
      map(([elements, input]) => {
        if (!['placeholder', 'group'].includes(this.type)) {
          return false;
        }

        return input && !elements.find((el:any) => el.name === input);
      }),
    );
  }

  createNewFromInput() {
    this.input$
      .pipe(first())
      .subscribe((input:string) => {
        this.createNew.emit(input);
      });
  }
}
