import {
  Component,
  Input,
  OnInit,
  ElementRef,
} from '@angular/core';
import { FormControl, NgControl } from "@angular/forms";
import { Observable, Subject } from "rxjs";
import { debounceTime, distinctUntilChanged, filter, map, switchMap, tap } from "rxjs/operators";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";
import { ApiV3FilterBuilder } from "core-components/api/api-v3/api-v3-filter-builder";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";

@Component({
  selector: 'op-ium-project-search',
  templateUrl: './project-search.component.html',
})
export class ProjectSearchComponent extends UntilDestroyedMixin implements OnInit {
  @Input('opFormBinding') projectFormControl:FormControl;

  public text = {
    noResultsFound: this.I18n.t('js.invite_user_modal.project.no_results'),
  };

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
        debounceTime(100),
        switchMap((searchTerm:string) => {
          const filters = new ApiV3FilterBuilder();
          if (searchTerm) {
            filters.add('name_and_identifier', '~', [searchTerm]);
          }
          return this.apiV3Service.projects.filtered(filters).get().pipe(map(collection => collection.elements));
        }),
      );
  }

  ngOnInit() {
    // Make sure we have initial data
    setTimeout(() => this.input$.next(''));
  }
}
