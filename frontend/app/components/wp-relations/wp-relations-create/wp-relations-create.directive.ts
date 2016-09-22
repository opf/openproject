import {wpDirectivesModule} from '../../../angular-modules';
import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {RelationType} from '../wp-relations.interfaces';
import {WorkPackageRelationsService} from '../wp-relations.service';
import {WorkPackageRelationsHierarchyService} from '../wp-relations-hierarchy/wp-relations-hierarchy.service';
import {WorkPackageNotificationService} from '../../wp-edit/wp-notification.service';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';

export class WorkPackageRelationsCreateController {

  public showRelationsCreateForm: boolean = false;
  public workPackage:WorkPackageResourceInterface;
  public selectedRelationType:RelationType;
  public selectedWpId:string;
  public externalFormToggle: boolean;
  public fixedRelationType:string;
  public relationTypes = this.wpRelationsService.getRelationTypes(true);
  public translatedRelationTitle = this.wpRelationsService.getTranslatedRelationTitle;

  constructor(protected I18n,
              protected $scope:ng.IScope,
              protected $rootScope:ng.IRootScopeService,
              protected wpRelationsService:WorkPackageRelationsService,
              protected wpRelationsHierarchyService:WorkPackageRelationsHierarchyService,
              protected wpNotificationsService:WorkPackageNotificationService,
              protected wpCacheService:WorkPackageCacheService) {

    var defaultRelationType = angular.isDefined(this.fixedRelationType) ? this.fixedRelationType : 'relatedTo';
    this.selectedRelationType = this.wpRelationsService.getRelationTypeObjectByName(defaultRelationType);

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
    addParent: this.I18n.t('js.relation_buttons.add_parent')
  };

  public createRelation() {

    if (!this.selectedRelationType || ! this.selectedWpId) {
      return;
    }

    switch (this.selectedRelationType.name) {
      case 'parent':
        this.changeParent();
        break;
      case 'children':
        this.addExistingChildRelation();
        break;
      default:
        this.createCommonRelation();
    }
  }

  protected addExistingChildRelation() {
    this.wpRelationsHierarchyService.addExistingChildWp(this.workPackage, this.selectedWpId)
      .then(newChildWp => this.$scope.$emit('wp-relations.addedChild', newChildWp))
      .catch(err => this.wpNotificationsService.handleErrorResponse(err, this.workPackage))
      .finally(() => this.toggleRelationsCreateForm());
  }

  protected createNewChildWorkPackage() {
    this.wpRelationsHierarchyService.addNewChildWp(this.workPackage);
  }

  protected changeParent() {
    this.wpRelationsHierarchyService.changeParent(this.workPackage, this.selectedWpId)
      .then(updatedWp => {
        console.log("wp after update", updatedWp)
        this.$rootScope.$broadcast('wp-relations.changedParent', {
          updatedWp: updatedWp,
          parentId: this.selectedWpId
        });
        this.wpNotificationsService.showSave(this.workPackage);
      })
      .catch(err => this.wpNotificationsService.handleErrorResponse(err, this.workPackage))
      .finally(this.toggleRelationsCreateForm());
  }

  protected createCommonRelation() {
    let relationType = this.selectedRelationType.name === 'relatedTo' ? this.selectedRelationType.id : this.selectedRelationType.name;

    this.wpRelationsService.addCommonRelation(this.workPackage, relationType, this.selectedWpId)
      .then(relation => {
        this.$scope.$emit('wp-relations.added', relation);
        this.wpNotificationsService.showSave(this.workPackage);
      })
      .catch(err => this.wpNotificationsService.handleErrorResponse(err, this.workPackage))
      .finally(() => this.toggleRelationsCreateForm());
  }

  public toggleRelationsCreateForm() {
    this.showRelationsCreateForm = !this.showRelationsCreateForm;
    this.externalFormToggle = !this.externalFormToggle;
  }
}

function wpRelationsCreate() {
  return {
    restrict: 'E',

    templateUrl: (el, attrs) => {
      return '/components/wp-relations/wp-relations-create/' + attrs.template + '.template.html';
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
