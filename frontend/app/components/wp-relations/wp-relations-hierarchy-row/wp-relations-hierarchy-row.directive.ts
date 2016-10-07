import {wpDirectivesModule} from '../../../angular-modules';
import {WorkPackageRelationsHierarchyService} from '../wp-relations-hierarchy/wp-relations-hierarchy.service';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {WorkPackageNotificationService} from '../../wp-edit/wp-notification.service';


class WpRelationsHierarchyRowDirectiveController {
  public workPackage;
  public relatedWorkPackage;
  public relationType;
  public showEditForm: boolean = false;
  public workPackagePath = this.PathHelper.workPackagePath;

  constructor(protected $scope:ng.IScope,
              protected $timeout,
              protected wpRelationsHierarchyService:WorkPackageRelationsHierarchyService,
              protected wpCacheService:WorkPackageCacheService,
              protected wpNotificationsService:WorkPackageNotificationService,
              protected PathHelper:op.PathHelper,
              protected I18n:op.I18n) {

    if (!this.relatedWorkPackage && this.relationType !== 'parent') {
      this.relatedWorkPackage = angular.copy(this.workPackage);
    }
  };

  public text = {
    change_parent: this.I18n.t('js.relation_buttons.change_parent'),
    remove_parent: this.I18n.t('js.relation_buttons.remove_parent'),
    remove_child: this.I18n.t('js.relation_buttons.remove_child'),
    remove: this.I18n.t('js.relation_buttons.remove'),
    parent: this.I18n.t('js.relation_labels.parent'),
    children: this.I18n.t('js.relation_labels.children')
  };

  public removeRelation() {
    if (this.relationType === 'child') {
      this.removeChild();

    } else if (this.relationType === 'parent') {
     this.removeParent();
    }
  }

  public isCurrentElement() {
    if (this.relationType !== 'child' && this.relationType !== 'parent') {
      return true;
    }
  }

  public isParent() {
    if (this.relationType === 'parent') {
      return true;
    }
  }

  protected removeChild() {
      this.wpRelationsHierarchyService.removeChild(this.relatedWorkPackage).then(exChildWp => {
        this.$scope.$emit('wp-relations.removedChild', exChildWp);
        this.wpNotificationsService.showSave(this.workPackage);
        this.$timeout(() => {
          angular.element('#hierarchy--add-exisiting-child').focus();
        });
      })
      .catch(err => this.wpNotificationsService.handleErrorResponse(err, this.relatedWorkPackage));
  }

  protected removeParent() {
    this.wpRelationsHierarchyService.removeParent(this.workPackage)
      .then((updatedWp) => {
        this.$scope.$emit('wp-relations.changedParent', {
          updatedWp: this.workPackage,
          parentId: null
        });
        this.wpNotificationsService.showSave(this.workPackage);
        this.$timeout(() => {
          angular.element('#hierarchy--add-parent').focus();
        });
      })
      .catch(err => this.wpNotificationsService.handleErrorResponse(err, this.relatedWorkPackage));

  }
}

function WpRelationsHierarchyRowDirective() {
  return {
    restrict: 'E',
    templateUrl: '/components/wp-relations/wp-relations-hierarchy-row/wp-relations-hierarchy-row.template.html',
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
