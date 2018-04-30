import {wpControllersModule} from '../../../angular-modules';
import {States} from '../../states.service';
import {AuthorisationService} from 'core-components/common/model-auth/model-auth.service';
import {Component, Inject, Input, OnInit, Output} from "@angular/core";
import {I18nToken} from "core-app/angular4-transition-utils";
import {EventEmitter} from "@angular/core";

export interface QuerySharingChange {
  isStarred:boolean;
  isPublic:boolean;
}

@Component({
  selector: 'query-sharing-form',
  template: require('!!raw-loader!./query-sharing-form.html')
})
export class QuerySharingForm implements OnInit {
  public canPublish:boolean = false;

  @Input() public isSave:boolean;
  @Input() public isStarred:boolean;
  @Input() public isPublic:boolean;
  @Output() public onChange = new EventEmitter<QuerySharingChange>();

  public text = {
    showInMenu: this.I18n.t('js.label_show_in_menu'),
    visibleForOthers: this.I18n.t('js.label_visible_for_others')
  };

  constructor(readonly states:States,
              readonly authorisationService:AuthorisationService,
              @Inject(I18nToken) readonly I18n:op.I18n) {
  }

  ngOnInit() {
    const form = this.states.query.form.value!;
    this.canPublish = form.schema.public.writable;
  }

  public get canStar() {
    return this.isSave ||
      this.authorisationService.can('query', 'star') ||
      this.authorisationService.can('query', 'unstar');
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
