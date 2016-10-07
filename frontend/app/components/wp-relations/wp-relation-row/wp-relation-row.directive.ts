import {wpDirectivesModule} from '../../../angular-modules';
import {RelatedWorkPackage, RelationResource} from '../wp-relations.interfaces';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {WorkPackageNotificationService} from '../../wp-edit/wp-notification.service';
import {WorkPackageRelationsService} from '../wp-relations.service';
import {RelationSortingAttribute} from '../wp-relations.directive';

class WpRelationRowDirectiveController {
  public relatedWorkPackage:RelatedWorkPackage;
  public relationType:string;
  public sortBy: RelationSortingAttribute;
  public showRelationInfo:boolean = false;

  public userInputs = {
    description: this.relatedWorkPackage.relatedBy.description,
    showDescriptionEditForm: false
  };

  public relation:RelationResource = this.relatedWorkPackage.relatedBy;

  constructor(protected $scope:ng.IScope,
              protected wpCacheService:WorkPackageCacheService,
              protected wpNotificationsService:WorkPackageNotificationService,
              protected wpRelationsService:WorkPackageRelationsService,
              protected I18n:op.I18n,
              protected PathHelper:op.PathHelper) {

    if (this.relation) {
      var relationType = this.wpRelationsService.getRelationTypeObjectByType(this.relation._type);
      this.relationType = angular.isDefined(relationType) ? this.wpRelationsService.getTranslatedRelationTitle(relationType.name) : 'unknown';
    }

  };

  public text = {
    removeButton: this.I18n.t('js.relation_buttons.remove')
  };

  public toggleUserDescriptionForm() {
    this.userInputs.showDescriptionEditForm = !this.userInputs.showDescriptionEditForm;
  }

  public getRelationDescriptor() {
    if (this.relation) {
      switch (this.sortBy) {
        case RelationSortingAttribute.RelatedWorkPackageType:
          return this.wpRelationsService.getRelationTypeObjectByType(this.relation._type).label;
        case RelationSortingAttribute.RelationType:
          return this.relatedWorkPackage.type.name;
        default:
          return this.relatedWorkPackage.type.name;
      }
    }
  }

  public removeRelation() {
    this.wpRelationsService.removeCommonRelation(this.relation)
      .then(() => {
        this.$scope.$emit('wp-relations.removed', this.relation);
        this.wpCacheService.updateWorkPackage(this.relatedWorkPackage);
        this.wpNotificationsService.showSave(this.relatedWorkPackage);
      })
      .catch(err => this.wpNotificationsService.handleErrorResponse(err, this.relatedWorkPackage));
  }
}

function WpRelationRowDirective() {
  return {
    restrict: 'E',
    templateUrl: '/components/wp-relations/wp-relation-row/wp-relation-row.template.html',
    scope: {
      relatedWorkPackage: '=',
      sortBy: '='
    },
    controller: WpRelationRowDirectiveController,
    controllerAs: '$ctrl',
    bindToController: true
  };
}

wpDirectivesModule.directive('wpRelationRow', WpRelationRowDirective);
