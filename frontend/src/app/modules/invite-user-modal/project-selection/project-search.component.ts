import {
  Component,
  Input,
  OnInit,
  ElementRef,
} from '@angular/core';
import { FormControl, NgControl } from "@angular/forms";
import { Observable, BehaviorSubject, combineLatest } from "rxjs";
import { debounceTime, distinctUntilChanged, filter, map, switchMap, tap } from "rxjs/operators";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";
import { ApiV3FilterBuilder } from "core-components/api/api-v3/api-v3-filter-builder";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";
import { ProjectResource } from "core-app/modules/hal/resources/project-resource";
import { CurrentUserService } from 'core-app/modules/current-user/current-user.service';

interface NgSelectProjectOption {
  value: ProjectResource;
  disabled: boolean;
};

@Component({
  selector: 'op-ium-project-search',
  templateUrl: './project-search.component.html',
})
export class ProjectSearchComponent extends UntilDestroyedMixin implements OnInit {
  @Input('opFormBinding') projectFormControl:FormControl;

  public text = {
    noResultsFound: this.I18n.t('js.invite_user_modal.project.no_results'),
    noInviteRights: 'No rights to invite',
  };

  public input$ = new BehaviorSubject<string|null>('');
  public items$:Observable<NgSelectProjectOption>;

  constructor(
    readonly I18n:I18nService,
    readonly elementRef:ElementRef,
    readonly apiV3Service:APIV3Service,
    readonly currentUserService:CurrentUserService,
  ) {
    super();

    this.items$ = combineLatest([
      this.input$.pipe(
        debounceTime(100),
        switchMap((searchTerm:string) => {
          const filters = new ApiV3FilterBuilder();
          if (searchTerm) {
            filters.add('name_and_identifier', '~', [searchTerm]);
          }
          return this.apiV3Service.projects
            .filtered(filters)
            .get()
            .pipe(map(collection => collection.elements));
        })
      ),
      this.currentUserService.capabilities$.pipe(
        map(capabilities => capabilities.filter(c => c.action.href.endsWith('/memberships/create')))
      ),
    ])
    .pipe(
      this.untilDestroyed(),
      map(([ projects, projectInviteCapabilities ]) => {
        const mapped = projects.map((project: ProjectResource) => ({
            value: project,
            disabled: !projectInviteCapabilities.find(cap => cap.context.id === project.id),
          }));
        mapped.sort(
          (a: NgSelectProjectOption, b: NgSelectProjectOption) => (a.disabled ? 1 : 0) - (b.disabled ? 1 : 0),
        );
        return mapped;
      })
    );
  }

  ngOnInit() {
    // Make sure we have initial data
    setTimeout(() => {
      if (!this.projectFormControl.value) {
        this.input$.next('');
      }
    });
  }

  public compareNgSelectItems(a: NgSelectProjectOption, b: NgSelectProjectOption) {
    console.log('compare', a.value.id, b.value.id);
    return a.value.id === b.value.id;
  }
}
