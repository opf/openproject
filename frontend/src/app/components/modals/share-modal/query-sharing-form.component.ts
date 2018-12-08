import {States} from '../../states.service';
import {AuthorisationService} from 'core-app/modules/common/model-auth/model-auth.service';
import {Component, EventEmitter, Input, Output} from "@angular/core";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {TableState} from "core-components/wp-table/table-state/table-state";

export interface QuerySharingChange {
  isStarred:boolean;
  isPublic:boolean;
}

@Component({
  selector: 'query-sharing-form',
  templateUrl: './query-sharing-form.html'
})
export class QuerySharingForm {
  @Input() public isSave:boolean;
  @Input() public isStarred:boolean;
  @Input() public isPublic:boolean;
  @Output() public onChange = new EventEmitter<QuerySharingChange>();

  public text = {
    showInMenu: this.I18n.t('js.label_star_query'),
    visibleForOthers: this.I18n.t('js.label_public_query')
  };

  constructor(readonly states:States,
              readonly tableState:TableState,
              readonly authorisationService:AuthorisationService,
              readonly I18n:I18nService) {
  }

  public get canStar() {
    return this.isSave ||
      this.authorisationService.can('query', 'star') ||
      this.authorisationService.can('query', 'unstar');
  }

  public get canPublish() {
    const form = this.tableState.queryForm.value!;

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
