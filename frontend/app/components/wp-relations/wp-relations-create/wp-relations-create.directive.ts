import {wpDirectivesModule} from '../../../angular-modules';
import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {RelationType} from "../wp-relations.interfaces";

export class WpRelationsCreateController {

  public showRelationsCreateForm: boolean = false;
  public workPackage:WorkPackageResourceInterface;
  public selectedRelationType:RelationType;
  public selectedWpId:string;
  public externalFormToggle: boolean;
  public fixedRelationType:string;
  public relationTypes = this.WpRelationsService.getRelationTypes(true);
  public translatedRelationTitle = this.WpRelationsService.getTranslatedRelationTitle;

  protected relationTitles = this.WpRelationsService.configuration.relationTitles;

  constructor(public I18n,
              protected $scope,
              protected $rootScope,
              protected $state,
              protected WpRelationsService,
              protected WpRelationsHierarchyService,
              protected wpNotificationsService,
              protected wpCacheService) {

    var defaultRelationType = angular.isDefined(this.fixedRelationType) ? this.fixedRelationType : 'relatedTo';
    this.selectedRelationType = this.WpRelationsService.getRelationTypeObjectByName(defaultRelationType);

    if (angular.isDefined(this.externalFormToggle)) {
      this.showRelationsCreateForm = this.externalFormToggle;
    }
  }

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
        break;
    }
  }

  protected addExistingChildRelation() {
    this.WpRelationsHierarchyService.addExistingChildWp(this.workPackage, this.selectedWpId)
      .then(newChildWp => this.$scope.$emit('wp-relations.addedChild', newChildWp))
      .catch(err => this.wpNotificationsService.handleErrorResponse(err, this.workPackage))
      .finally(this.toggleRelationsCreateForm());
  }

  protected createNewChildWorkPackage() {
    this.WpRelationsHierarchyService.addNewChildWp(this.workPackage);
  }

  protected changeParent() {
    this.WpRelationsHierarchyService.changeParent(this.workPackage, this.selectedWpId)
      .then(updatedWp => {
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

    this.WpRelationsService.addCommonRelation(this.workPackage, relationType, this.selectedWpId)
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
    replace: true,

    templateUrl: (el, attrs) => {
      return '/components/wp-relations/wp-relations-create/' + attrs.template + '.template.html';
    },

    scope: {
      workPackage: '=?',
      fixedRelationType: '@?',
      externalFormToggle: '=?'
    },

    controller: WpRelationsCreateController,
    bindToController: true,
    controllerAs: '$relationsCreateCtrl',
  };
}

wpDirectivesModule.directive('wpRelationsCreate', wpRelationsCreate);
