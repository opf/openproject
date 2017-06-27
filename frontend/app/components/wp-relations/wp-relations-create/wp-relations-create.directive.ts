import {wpDirectivesModule} from '../../../angular-modules';
import {RelationResource} from '../../api/api-v3/hal-resources/relation-resource.service';
import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {WorkPackageNotificationService} from '../../wp-edit/wp-notification.service';
import {WorkPackageRelationsHierarchyService} from '../wp-relations-hierarchy/wp-relations-hierarchy.service';
import {WorkPackageRelationsService} from '../wp-relations.service';

export class WorkPackageRelationsCreateController {

  public showRelationsCreateForm: boolean = false;
  public workPackage:WorkPackageResourceInterface;
  public selectedRelationType:string = RelationResource.DEFAULT();
  public selectedWpId:string;
  public externalFormToggle: boolean;
  public fixedRelationType:string;
  public relationTypes = RelationResource.LOCALIZED_RELATION_TYPES(false);

  public canAddChildren = !!this.workPackage.addChild;
  public canLinkChildren = !!this.workPackage.changeParent;
  public isDisabled = false;

  constructor(protected I18n:op.I18n,
              protected $scope:ng.IScope,
              protected $rootScope:ng.IRootScopeService,
              protected $element:ng.IAugmentedJQuery,
              protected $timeout:ng.ITimeoutService,
              protected wpRelations:WorkPackageRelationsService,
              protected wpRelationsHierarchyService:WorkPackageRelationsHierarchyService,
              protected wpNotificationsService:WorkPackageNotificationService,
              protected wpCacheService:WorkPackageCacheService) {

    if (angular.isDefined(this.fixedRelationType)) {
      this.selectedRelationType = this.fixedRelationType;
    }

    if (angular.isDefined(this.externalFormToggle)) {
      this.showRelationsCreateForm = this.externalFormToggle;
    }
  }

  public text = {
    save: this.I18n.t('js.relation_buttons.save'),
    abort: this.I18n.t('js.relation_buttons.abort'),
    addNewChild: this.I18n.t('js.relation_buttons.add_new_child'),
    addExistingChild: this.I18n.t('js.relation_buttons.add_existing_child'),
    addNewRelation: this.I18n.t('js.relation_buttons.add_new_relation'),
    addParent: this.I18n.t('js.relation_buttons.add_parent'),
    relationType: this.I18n.t('js.relation_labels.relation_type')
  };

  public createRelation() {

    if (!this.selectedRelationType || ! this.selectedWpId) {
      return;
    }

    let promise;
    this.isDisabled = true;
    switch (this.selectedRelationType) {
      case 'parent':
        promise = this.changeParent();
        break;
      case 'children':
        promise = this.addExistingChildRelation();
        break;
      default:
        promise = this.createCommonRelation();
    }

    promise.finally(() => {
      this.isDisabled = false;
    });
  }

  protected addExistingChildRelation() {
    return this.wpRelationsHierarchyService.addExistingChildWp(this.workPackage, this.selectedWpId)
      .then(() => this.wpCacheService.loadWorkPackage(this.workPackage.id, true))
      .catch(err => this.wpNotificationsService.handleErrorResponse(err, this.workPackage))
      .finally(() => this.toggleRelationsCreateForm());
  }

  protected createNewChildWorkPackage() {
    this.wpRelationsHierarchyService.addNewChildWp(this.workPackage);
  }

  protected changeParent() {
    this.toggleRelationsCreateForm();
    return this.wpRelationsHierarchyService.changeParent(this.workPackage, this.selectedWpId)
      .then((updatedWp:WorkPackageResourceInterface) => {
        this.$timeout(() => {
          angular.element('#hierarchy--parent').focus();
        });
      })
      .catch((err:any) => this.wpNotificationsService.handleErrorResponse(err, this.workPackage));
  }

  protected createCommonRelation() {
    return this.wpRelations.addCommonRelation(this.workPackage, this.selectedRelationType, this.selectedWpId)
      .then(relation => {
        this.wpNotificationsService.showSave(this.workPackage);
      })
      .catch(err => this.wpNotificationsService.handleErrorResponse(err, this.workPackage))
      .finally(() => this.toggleRelationsCreateForm());
  }

  public toggleRelationsCreateForm() {
    this.showRelationsCreateForm = !this.showRelationsCreateForm;
    this.externalFormToggle = !this.externalFormToggle;

    this.$timeout(() => {
      if (!this.showRelationsCreateForm) {
        // Reset value
        this.selectedWpId = '';
        this.$element.find('.-focus-after-save').first().focus();
      }
    });
  }
}

function wpRelationsCreate() {
  return {
    restrict: 'E',

    templateUrl: (el:ng.IAugmentedJQuery, attrs:ng.IAttributes) => {
      return '/components/wp-relations/wp-relations-create/' + attrs['template'] + '.template.html';
    },

    scope: {
      workPackage: '=?',
      fixedRelationType: '@?',
      externalFormToggle: '=?'
    },

    controller: WorkPackageRelationsCreateController,
    bindToController: true,
    controllerAs: '$ctrl',
  };
}

wpDirectivesModule.directive('wpRelationsCreate', wpRelationsCreate);
