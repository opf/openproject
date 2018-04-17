import {wpDirectivesModule} from '../../../angular-modules';
import {RelationResource} from 'core-app/modules/hal/resources/relation-resource';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {WorkPackageNotificationService} from '../../wp-edit/wp-notification.service';
import {WorkPackageRelationsHierarchyService} from '../wp-relations-hierarchy/wp-relations-hierarchy.service';
import {WorkPackageRelationsService} from '../wp-relations.service';

export class WorkPackageRelationsCreateController {

  public showRelationsCreateForm:boolean = false;
  public workPackage:WorkPackageResource;
  public selectedRelationType:string = RelationResource.DEFAULT();
  public selectedWpId:string;
  public externalFormToggle:boolean;
  public fixedRelationType:string;
  public relationTypes = RelationResource.LOCALIZED_RELATION_TYPES(false);

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
  }

  $onInit() {
    if (this.fixedRelationType) {
      this.selectedRelationType = this.fixedRelationType;
    }

    if (this.externalFormToggle) {
      this.showRelationsCreateForm = this.externalFormToggle;
    }
  }

  public text = {
    save: this.I18n.t('js.relation_buttons.save'),
    abort: this.I18n.t('js.relation_buttons.abort'),
    addNewRelation: this.I18n.t('js.relation_buttons.add_new_relation')
  };

  public createRelation() {

    if (!this.selectedRelationType || !this.selectedWpId) {
      return;
    }

    this.isDisabled = true;
    this.createCommonRelation()
      .catch(() => this.isDisabled = false)
      .then(() => this.isDisabled = false);
  }

  protected async createCommonRelation() {
    return this.wpRelations.addCommonRelation(this.workPackage,
      this.selectedRelationType,
      this.selectedWpId)
      .then(relation => {
        this.wpNotificationsService.showSave(this.workPackage);
        this.toggleRelationsCreateForm();
      })
      .catch(err => {
        this.wpNotificationsService.handleErrorResponse(err, this.workPackage);
        this.toggleRelationsCreateForm();
      });
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

function wpRelationsCreate():any {
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
