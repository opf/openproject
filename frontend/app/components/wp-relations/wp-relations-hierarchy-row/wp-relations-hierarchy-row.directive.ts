import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {wpDirectivesModule} from '../../../angular-modules';
import {WorkPackageRelationsHierarchyService} from '../wp-relations-hierarchy/wp-relations-hierarchy.service';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {WorkPackageNotificationService} from '../../wp-edit/wp-notification.service';

class WpRelationsHierarchyRowDirectiveController {
  public workPackage:WorkPackageResourceInterface;
  public relatedWorkPackage:WorkPackageResourceInterface;
  public relationType:any;
  public showEditForm: boolean = false;
  public workPackagePath = this.PathHelper.workPackagePath;
  public canModifyHierarchy: boolean = false;

  constructor(protected $scope: ng.IScope,
              protected $timeout:ng.ITimeoutService,
              protected wpRelationsHierarchyService: WorkPackageRelationsHierarchyService,
              protected wpCacheService: WorkPackageCacheService,
              protected wpNotificationsService: WorkPackageNotificationService,
              protected PathHelper: op.PathHelper,
              protected I18n: op.I18n) {

    this.canModifyHierarchy = !!this.workPackage.changeParent;
  };

  public text = {
    change_parent:this.I18n.t('js.relation_buttons.change_parent'),
    remove_parent:this.I18n.t('js.relation_buttons.remove_parent'),
    remove_child:this.I18n.t('js.relation_buttons.remove_child'),
    remove:this.I18n.t('js.relation_buttons.remove'),
    parent:this.I18n.t('js.relation_labels.parent'),
    children:this.I18n.t('js.relation_labels.children')
  };

  public get relationReady() {
    return this.relatedWorkPackage && this.relatedWorkPackage.$loaded;
  }

  public get relationClassName() {
    if (this.isCurrentElement()) {
      return 'self';
    }

    return this.relationType;
  }

  public removeRelation() {
    if (this.relationType === 'child') {
      this.removeChild();

    } else if (this.relationType === 'parent') {
      this.removeParent();
    }
  }

  public isCurrentElement():boolean {
    return (this.relationType !== 'child' && this.relationType !== 'parent');
  }

  public isParent() {
    return this.relationType === 'parent';
  }

  protected removeChild() {
    this.wpRelationsHierarchyService
      .removeChild(this.relatedWorkPackage)
      .then(() => {
        this.wpCacheService.loadWorkPackage(this.workPackage.id, true);
        this.wpNotificationsService.showSave(this.workPackage);
        this.$timeout(() => {
          angular.element('#hierarchy--add-exisiting-child').focus();
        });
      })
      .catch((err:any) => this.wpNotificationsService.handleErrorResponse(err, this.relatedWorkPackage));
  }

  protected removeParent() {
    this.wpRelationsHierarchyService
      .removeParent(this.workPackage)
      .then(() => {
        this.wpNotificationsService.showSave(this.workPackage);
        this.$timeout(() => {
          angular.element('#hierarchy--add-parent').focus();
        });
      })
      .catch((err:any) => this.wpNotificationsService.handleErrorResponse(err, this.relatedWorkPackage));

  }
}

function WpRelationsHierarchyRowDirective() {
  return {
    restrict:'E',
    templateUrl:'/components/wp-relations/wp-relations-hierarchy-row/wp-relations-hierarchy-row.template.html',
    scope:{
      indentBy:'@?',
      workPackage:'=',
      relatedWorkPackage:'=?',
      relationType:'@'
    },
    controller:WpRelationsHierarchyRowDirectiveController,
    controllerAs:'$ctrl',
    bindToController:true
  };
}

wpDirectivesModule.directive('wpRelationsHierarchyRow', WpRelationsHierarchyRowDirective);
