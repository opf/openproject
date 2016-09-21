import {wpDirectivesModule} from '../../../angular-modules';
import {
  WorkPackageResource,
  WorkPackageResourceInterface
} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {RelatedWorkPackage, RelationResource} from '../wp-relations.interfaces';


class WpRelationRowDirectiveController {
  public relatedWorkPackage:RelatedWorkPackage;
  public relationType:string;

  public showRelationInfo:boolean = false;

  public userInputs = {
    description: this.relatedWorkPackage.relatedBy.description,
    showDescriptionEditForm: false
  };

  public relation:RelationResource = this.relatedWorkPackage.relatedBy;

  constructor(public I18n,
              protected $scope:ng.IScope,
              protected wpCacheService,
              protected PathHelper,
              protected wpNotificationsService,
              protected wpRelationsService) {
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

  public removeRelation() {
    this.wpRelationsService.removeCommonRelation(this.relation)
      .then(() => {
        this.$scope.$emit('wp-relations.removed', this.relation);
        this.wpCacheService.updateWorkPackage([this.relatedWorkPackage]);
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
      relatedWorkPackage: '='
    },
    controller: WpRelationRowDirectiveController,
    controllerAs: '$ctrl',
    bindToController: true
  };
}

wpDirectivesModule.directive('wpRelationRow', WpRelationRowDirective);
