import {
  Component,
  Input,
  OnInit,
  ElementRef,
} from '@angular/core';
import { FormControl } from '@angular/forms';
import { BehaviorSubject, combineLatest } from 'rxjs';
import { debounceTime, map, switchMap } from 'rxjs/operators';
import { APIV3Service } from 'core-app/core/apiv3/api-v3.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { ProjectResource } from 'core-app/features/hal/resources/project-resource';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { ApiV3FilterBuilder } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';

interface NgSelectProjectOption {
  project:ProjectResource,
  disabled:boolean;
}

@Component({
  selector: 'op-ium-project-search',
  templateUrl: './project-search.component.html',
})
export class ProjectSearchComponent extends UntilDestroyedMixin implements OnInit {
  @Input('opFormBinding') projectFormControl:FormControl;

  public text = {
    noResultsFound: this.I18n.t('js.invite_user_modal.project.no_results'),
    noInviteRights: this.I18n.t('js.invite_user_modal.project.no_invite_rights'),
  };

  public input$ = new BehaviorSubject<string|null>('');

  public items$ = combineLatest([
    this.input$.pipe(
      debounceTime(100),
      switchMap((searchTerm:string) => {
        const filters = new ApiV3FilterBuilder();
        filters.add('active', '=', true);
        if (searchTerm) {
          filters.add('name_and_identifier', '~', [searchTerm]);
        }
        return this.apiV3Service.projects
          .filtered(filters)
          .get()
          .pipe(map((collection) => collection.elements));
      }),
    ),
    this.currentUserService.capabilities$.pipe(
      map((capabilities) => capabilities.filter((c) => c.action.href.endsWith('/memberships/create'))),
    ),
  ])
    .pipe(
      this.untilDestroyed(),
      map(([projects, projectInviteCapabilities]) => {
        const mapped = projects.map((project:ProjectResource) => ({
          project,
          disabled: !projectInviteCapabilities.find((cap) => cap.context.id === project.id),
        }));
        mapped.sort(
          (a:NgSelectProjectOption, b:NgSelectProjectOption) => (a.disabled ? 1 : 0) - (b.disabled ? 1 : 0),
        );
        return mapped;
      }),
    );

  constructor(
    readonly I18n:I18nService,
    readonly elementRef:ElementRef,
    readonly apiV3Service:APIV3Service,
    readonly currentUserService:CurrentUserService,
  ) {
    super();
  }

  ngOnInit() {
    // Make sure we have initial data
    setTimeout(() => this.input$.next(''));
  }

  compareWith = (a:NgSelectProjectOption, b:ProjectResource) => a.project.id === b.id;
}
