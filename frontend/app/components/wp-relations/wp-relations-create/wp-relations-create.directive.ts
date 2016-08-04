import {wpTabsModule} from '../../../angular-modules';

export class WpRelationsCreateController {

  public showRelationsCreateForm: boolean = false;
  public availableRelationTypes: Array<any> = [];

  public selectedRelationType;

  protected workPackage;
  protected relationsPanelCtrl;
  protected relationTitles;

  constructor(protected $scope,
              protected NotificationsService,
              protected wpRelations,
              protected I18n) {

    this.relationTitles = {
      parent: I18n.t('js.relation_labels.parent'),
      children: I18n.t('js.relation_labels.children'),
      relatedTo: I18n.t('js.relation_labels.relates'),
      duplicates: I18n.t('js.relation_labels.duplicates'),
      duplicated: I18n.t('js.relation_labels.duplicated'),
      blocks: I18n.t('js.relation_labels.blocks'),
      blocked: I18n.t('js.relation_labels.blocked'),
      precedes: I18n.t('js.relation_labels.precedes'),
      follows: I18n.t('js.relation_labels.follows')
    };

  }

  public toggleRelationsCreateForm() {
    this.showRelationsCreateForm = !this.showRelationsCreateForm;
    if (this.workPackage !== this.$scope.relationsPanelCtrl.workPackage) {
      this.initParentCtrlData();
    }
    if (this.showRelationsCreateForm) {
      this.loadWpRelationGroups();

      // set initial relation type
      this.selectedRelationType = _.find(this.availableRelationTypes, {name: 'relatedTo'});
    }
  }

  protected loadWpRelationGroups() {
    this.availableRelationTypes.length = 0;
    angular.extend(this.availableRelationTypes, this.wpRelations.getWpRelationGroups(this.workPackage));
  }
  // TODO: logic already available through wp-relations directive
  // use it..
  public createRelation() {
      this.selectedRelationType.addWpRelation(this.relationsPanelCtrl.wpToAddId).then((succ) => {
        this.relationsPanelCtrl.refreshRelations();
      }, (errorResponse) => {
        // TODO: add I18n
        this.NotificationsService.addError('Could not add relation due to the following reason:', [errorResponse.data.message]);
      }).finally(() => {
        this.toggleRelationsCreateForm();
      });
  }

  protected initParentCtrlData() {
    this.relationsPanelCtrl = this.$scope.relationsPanelCtrl;
    this.workPackage = this.relationsPanelCtrl.workPackage;
  }





}

function wpRelationsCreate() {
  return {
    restrict: 'E',
    replace: true,
    templateUrl: '/components/wp-relations/wp-relations-create/wp-relations-create.template.html',
    controller: WpRelationsCreateController,
    bindToController: true,
    controllerAs: 'createCtrl',
    require: ['^relationsPanel'],
    link: function(scope, element, attrs, ctrls) {
      scope.relationsPanelCtrl = ctrls[0];
    }
  };
}

wpTabsModule.directive('wpRelationsCreate', wpRelationsCreate);
