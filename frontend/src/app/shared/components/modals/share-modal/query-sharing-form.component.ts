import { States } from 'core-app/core/states/states.service';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import {
  Component, EventEmitter, Input, Output,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';

export interface QuerySharingChange {
  isStarred:boolean;
  isPublic:boolean;
}

@Component({
  selector: 'query-sharing-form',
  templateUrl: './query-sharing-form.html',
})
export class QuerySharingFormComponent {
  @Input() public isSave:boolean;

  @Input() public isStarred:boolean;

  @Input() public isPublic:boolean;

  @Output() public onChange = new EventEmitter<QuerySharingChange>();

  public text = {
    showInMenu: this.I18n.t('js.label_star_query'),
    visibleForOthers: this.I18n.t('js.label_public_query'),

    showInMenuText: this.I18n.t('js.work_packages.query.star_text'),
    visibleForOthersText: this.I18n.t('js.work_packages.query.public_text'),
  };

  constructor(readonly states:States,
    readonly querySpace:IsolatedQuerySpace,
    readonly authorisationService:AuthorisationService,
    readonly I18n:I18nService) {
  }

  public get canStar() {
    return this.isSave
      || this.authorisationService.can('query', 'star')
      || this.authorisationService.can('query', 'unstar');
  }

  public get canPublish() {
    const form = this.querySpace.queryForm.value!;

    return this.authorisationService.can('query', 'updateImmediately')
      && form.schema.public.writable;
  }

  public updateStarred(val:boolean) {
    this.isStarred = val;
    this.changed();
  }

  public updatePublic(val:boolean) {
    this.isPublic = val;
    this.changed();
  }

  public changed() {
    this.onChange.emit({ isStarred: !!this.isStarred, isPublic: !!this.isPublic });
  }
}
