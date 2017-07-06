import {wpControllersModule} from '../../../angular-modules';
import {States} from '../../states.service';

export class QuerySharingForm {
  public canPublish:boolean = false;

  public isSave:boolean;
  public isStarred:boolean;
  public isPublic:boolean;
  public onChange:(args:any) => void;

  public text:any;

  constructor(public $scope:ng.IScope,
              public states:States,
              public AuthorisationService:any,
              public I18n:op.I18n) {
    const query = this.states.query.resource.value!;
    const form = states.query.form.value!;

    this.canPublish = form.schema.public.writable;
    this.text = {
     showInMenu: I18n.t('js.label_show_in_menu'),
     visibleForOthers: I18n.t('js.label_visible_for_others')
    };
  }

  public get canStar() {
    return this.isSave ||
      this.AuthorisationService.can('query', 'star') ||
      this.AuthorisationService.can('query', 'unstar');
  }

  public changed() {
    this.onChange({ isStarred: !!this.isStarred, isPublic: !!this.isPublic });
  }
}

wpControllersModule.component('querySharingForm', {
  templateUrl: '/components/modals/share-modal/query-sharing-form.html',
  controller: QuerySharingForm,
  bindings: {
    onChange: '&',
    isStarred: '<',
    isPublic: '<',
    isSave: '<?'
  }
});
