import {wpDirectivesModule} from '../../../angular-modules';
import {
  WorkPackageResource,
  WorkPackageResourceInterface
} from "../../api/api-v3/hal-resources/work-package-resource.service";


class WpRelationsHierarchyRowDirectiveController {
  public workPackage;
  public relatedWorkPackage;
  public relationType;
  public showEditForm: boolean = false;
  public workPackagePath = this.PathHelper.workPackagePath;

  constructor(public I18n,
              protected $scope,
              protected WpRelationsHierarchyService,
              protected wpNotificationsService,
              protected wpCacheService,
              protected PathHelper,
              protected wpNotificationsService) {

    if (!this.relatedWorkPackage && this.relationType !== 'parent') {
      this.relatedWorkPackage = angular.copy(this.workPackage);
    }
  };

  public removeRelation() {
    if (this.relationType === 'child') {
      this.removeChild();

    }else if (this.relationType === 'parent') {
     this.removeParent();
    }
  }

  protected removeChild() {
      this.WpRelationsHierarchyService.removeChild(this.relatedWorkPackage).then(exChildWp => {
        this.$scope.$emit('wp-relations.removedChild', exChildWp);
        this.wpNotificationsService.showSave(this.workPackage);
      })
      .catch(err => this.wpNotificationsService.handleErrorResponse(err, this.relatedWorkPackage));;
  }

  protected removeParent() {
    this.WpRelationsHierarchyService.removeParent(this.workPackage)
      .then((updatedWp) => {
        this.$scope.$emit('wp-relations.changedParent', {
          updatedWp: this.workPackage,
          parentId: null
        });
        this.wpNotificationsService.showSave(this.workPackage);
      })
      .catch(err => this.wpNotificationsService.handleErrorResponse(err, this.relatedWorkPackage));;
  }
}

function WpRelationsHierarchyRowDirective() {
  return {
    restrict: 'E',
    templateUrl: '/components/wp-relations/wp-relations-hierarchy-row/wp-relations-hierarchy-row.template.html',
    replace: true,
    scope: {
      indentBy: '@?',
      workPackage: '=',
      relatedWorkPackage: '=?',
      relationType: '@'
    },
    controller: WpRelationsHierarchyRowDirectiveController,
    controllerAs: '$ctrl',
    bindToController: true
  };
}

wpDirectivesModule.directive('wpRelationsHierarchyRow', WpRelationsHierarchyRowDirective);
