import {
  Component,
  Input,
  EventEmitter,
  Output,
  ElementRef,
} from '@angular/core';
import {FormControl} from "@angular/forms";
import {Observable, Subject} from "rxjs";
import {debounceTime, distinctUntilChanged, filter, map, switchMap, tap} from "rxjs/operators";
import {APIV3Service} from "core-app/modules/apiv3/api-v3.service";
import {ApiV3FilterBuilder} from "core-components/api/api-v3/api-v3-filter-builder";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {UntilDestroyedMixin} from "core-app/helpers/angular/until-destroyed.mixin";

@Component({
  selector: 'op-ium-project-search',
  templateUrl: './project-search.component.html',
})
export class InviteProjectSearchComponent extends UntilDestroyedMixin {
  @Input() projectFormControl:FormControl;

  public input$ = new Subject<string|null>();
  public items$:Observable<any>;

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
  }
}
