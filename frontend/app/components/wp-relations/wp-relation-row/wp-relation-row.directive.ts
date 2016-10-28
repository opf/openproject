import {wpDirectivesModule} from '../../../angular-modules';
import {RelatedWorkPackage} from '../wp-relations.interfaces';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {WorkPackageNotificationService} from '../../wp-edit/wp-notification.service';
import {WorkPackageRelationsService} from '../wp-relations.service';
import {
  RelationResourceInterface,
  RelationResource
} from '../../api/api-v3/hal-resources/relation-resource.service';
import {RelationSortingAttribute} from '../wp-relations.directive';

class WpRelationRowDirectiveController {
  public relatedWorkPackage:RelatedWorkPackage;
  public relationType:string;
  public availableRelationTypes: RelationResourceInterface[];
  public selectedRelationType: RelationResourceInterface;
  public groupRelationsBy: RelationSortingAttribute;
  public showRelationInfo: boolean = false;

  public userInputs = {
    description:this.relatedWorkPackage.relatedBy.description,
    showDescriptionEditForm:false,
    showRelationTypesForm: false,
    showRelationInfo:false
  };

  public relation: RelationResourceInterface = this.relatedWorkPackage.relatedBy;
  public text: Object;

  constructor(protected $scope:ng.IScope,
              protected $timeout:ng.ITimeoutService,
              protected $http,
              protected wpCacheService: WorkPackageCacheService,
              protected wpNotificationsService: WorkPackageNotificationService,
              protected wpRelationsService: WorkPackageRelationsService,
              protected I18n: op.I18n,
              protected PathHelper: op.PathHelper) {

    this.availableRelationTypes = wpRelationsService.getRelationTypes(true);
    this.selectedRelationType = _.find(this.availableRelationTypes, {'name': this.relation.type});
  };

  public saveDescription() {
    this.relation.updateImmediately({
      description: this.relation.description
    }).then(() => {
      this.userInputs.showDescriptionEditForm = false;
      this.wpNotificationsService.showSave(this.relatedWorkPackage);
    });
  }

  public saveRelationType() {
    this.relation.updateImmediately({
      type: this.selectedRelationType.name
    }).then((savedRelation) => {
      this.wpNotificationsService.showSave(this.relatedWorkPackage);

      this.relatedWorkPackage.relatedBy = savedRelation;
      this.relation = savedRelation;

      this.userInputs.showRelationTypesForm = false;
    });
  }

  public text = {
    removeButton: this.I18n.t('js.relation_buttons.remove')
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
      relatedWorkPackage:'=',
      groupRelationsBy: '='
    },
    controller:WpRelationRowDirectiveController,
    controllerAs:'$ctrl',
    bindToController:true
  };
}

wpDirectivesModule.directive('wpRelationRow', WpRelationRowDirective);
