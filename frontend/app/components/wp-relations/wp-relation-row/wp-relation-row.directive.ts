import {wpDirectivesModule} from '../../../angular-modules';
import {RelatedWorkPackage} from '../wp-relations.interfaces';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {WorkPackageNotificationService} from '../../wp-edit/wp-notification.service';
import {WorkPackageRelationsService} from '../wp-relations.service';
import {
  RelationResourceInterface,
  RelationResource
} from '../../api/api-v3/hal-resources/relation-resource.service';

class WpRelationRowDirectiveController {
  public relatedWorkPackage: RelatedWorkPackage;
  public relationType: string;

  public showRelationInfo: boolean = false;

  public userInputs = {
    description:this.relatedWorkPackage.relatedBy.description,
    showDescriptionEditForm:false
  };

  public relation: RelationResourceInterface = this.relatedWorkPackage.relatedBy;
  public text: Object;

  constructor(protected $scope: ng.IScope,
              protected $timeout,
              protected wpCacheService: WorkPackageCacheService,
              protected wpNotificationsService: WorkPackageNotificationService,
              protected wpRelationsService: WorkPackageRelationsService,
              protected I18n: op.I18n,
              protected PathHelper: op.PathHelper) {

    this.text = {
      removeButton:this.I18n.t('js.relation_buttons.remove')
    };

    RelationResource.TYPES.forEach((type) => {
      this.text[type] = I18n.t('js.relation_labels.' + type);
    });
  };

  public toggleUserDescriptionForm() {
    this.userInputs.showDescriptionEditForm = !this.userInputs.showDescriptionEditForm;
  }

  public removeRelation() {
    this.relation.delete().then(() => {
      this.$scope.$emit('wp-relations.removed', this.relation);
      this.wpCacheService.updateWorkPackage(this.relatedWorkPackage);
      this.wpNotificationsService.showSave(this.relatedWorkPackage);
      this.$timeout(() => {
        angular.element('#relation--add-relation').focus();
      });
    })
      .catch(err => this.wpNotificationsService.handleErrorResponse(err, this.relatedWorkPackage));
  }
}

function WpRelationRowDirective() {
  return {
    restrict:'E',
    templateUrl:'/components/wp-relations/wp-relation-row/wp-relation-row.template.html',
    scope:{
      relatedWorkPackage:'='
    },
    controller:WpRelationRowDirectiveController,
    controllerAs:'$ctrl',
    bindToController:true
  };
}

wpDirectivesModule.directive('wpRelationRow', WpRelationRowDirective);
