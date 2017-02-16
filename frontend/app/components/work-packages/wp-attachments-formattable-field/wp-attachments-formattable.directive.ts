import {InsertMode, ViewMode} from './wp-attachments-formattable.enums';
import {
  DropModel,
  EditorModel,
  MarkupModel,
  FieldModel,
  SingleAttachmentModel
} from './wp-attachments-formattable.models';
import {
  WorkPackageResourceInterface
} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageSingleViewController} from '../wp-single-view/wp-single-view.directive';
import {WorkPackageEditFormController} from '../../wp-edit/wp-edit-form.directive';
import {KeepTabService} from '../../wp-panels/keep-tab/keep-tab.service';
import {openprojectModule} from '../../../angular-modules';
import {WorkPackageCacheService} from '../work-package-cache.service';
import {WorkPackageEditModeStateService} from '../../wp-edit/wp-edit-mode-state.service';

export class WpAttachmentsFormattableController {
  private viewMode:ViewMode = ViewMode.SHOW;

  constructor(protected $scope:ng.IScope,
              protected $element:ng.IAugmentedJQuery,
              protected $rootScope:ng.IRootScopeService,
              protected $location:ng.ILocationService,
              protected wpCacheService:WorkPackageCacheService,
              protected wpEditModeState:WorkPackageEditModeStateService,
              protected $timeout:ng.ITimeoutService,
              protected $q:ng.IQService,
              protected $state:ng.ui.IStateService,
              protected loadingIndicator:any,
              protected keepTab:KeepTabService) {

    $element.on('drop', this.handleDrop);
    $element.on('dragover', this.highlightDroppable);
    $element.on('dragleave', this.removeHighlight);

    // There's a weird TS warning ocurring here:
    // Argument of type 'string' is not assignable to parameter of type '{ [key: string]: any; }'
    // TS appears to be choosing the wrong function declaration
    ($element as any).on('dragenter dragleave dragover', this.prevDefault);
  }

  public handleDrop = (evt:JQueryEventObject):void => {
    evt.preventDefault();
    evt.stopPropagation();

    const textarea:ng.IAugmentedJQuery = this.$element.find('textarea');
    this.viewMode = (textarea.length > 0) ? ViewMode.EDIT : ViewMode.SHOW;

    const originalEvent = (evt.originalEvent as DragEvent);
    const workPackage:WorkPackageResourceInterface = (this.$scope as any).workPackage;
    const dropData:DropModel = new DropModel(this.$location, originalEvent.dataTransfer, workPackage);

    var description:any;

    if (this.viewMode === ViewMode.EDIT) {
      description = new EditorModel(textarea, new MarkupModel());
    }
    else {
      description = new FieldModel(workPackage, new MarkupModel());
    }

    if (angular.isUndefined(dropData.webLinkUrl) && angular.isUndefined(dropData.files)) {
      return;
    }

    if (dropData.isUpload) {
      if (dropData.filesAreValidForUploading()) {
        if (!dropData.isDelayedUpload) {
          workPackage
            .uploadAttachments(<any> dropData.files)
            .then(attachments => attachments.elements)
            .then((updatedAttachments:any) => {
              if (angular.isUndefined(updatedAttachments)) {
                return;
              }
              updatedAttachments = this.sortAttachments(updatedAttachments);

              if (dropData.filesCount === 1) {
                this.insertSingleAttachment(updatedAttachments, description);
              }
              else if (dropData.filesCount > 1) {
                this.insertMultipleAttachments(dropData, updatedAttachments, description);
              }

              description.save();
          });
        }
        else {
          this.insertDelayedAttachments(dropData, description, workPackage);
        }
      }
    }
    else {
      this.insertUrls(dropData, description);
    }
    this.openDetailsView(workPackage.id.toString());
    this.removeHighlight();
  };

  protected sortAttachments(updatedAttachments:any) {
    updatedAttachments.sort(function (a:any, b:any) {
      return a.id > b.id ? 1 : -1;
    });
    return updatedAttachments;
  }

  protected insertSingleAttachment(updatedAttachments:any, description:any) {
    const currentFile:SingleAttachmentModel =
      new SingleAttachmentModel(updatedAttachments[updatedAttachments.length - 1]);
    description.insertAttachmentLink(
      currentFile.url,
      (currentFile.isAnImage) ? InsertMode.INLINE : InsertMode.ATTACHMENT);
  }

  protected insertMultipleAttachments(dropData:DropModel, updatedAttachments:any, description:any):void {
    for (let i:number = updatedAttachments.length - 1;
         i >= updatedAttachments.length - dropData.filesCount;
         i--) {
      description.insertAttachmentLink(
        updatedAttachments[i].downloadLocation.href,
        InsertMode.ATTACHMENT,
        true);
    }
  }

  protected insertDelayedAttachments(dropData:DropModel, description:any, workPackage: WorkPackageResourceInterface):void {
    for (var i = 0; i < dropData.files.length; i++) {
      var currentFile = new SingleAttachmentModel(dropData.files[i]);
      var insertMode = currentFile.isAnImage ? InsertMode.INLINE : InsertMode.ATTACHMENT;
      description.insertAttachmentLink(dropData.files[i].name.replace(/ /g, '_'), insertMode, true);
      workPackage.pendingAttachments.push((dropData.files[i]));
    }

    description.save();
  }

  protected insertUrls(dropData: DropModel, description:any):void {
    const insertUrl:string = dropData.isAttachmentOfCurrentWp() ? dropData.removeHostInformationFromUrl() : dropData.webLinkUrl;
    const insertAlternative:InsertMode = dropData.isWebImage() ? InsertMode.INLINE : InsertMode.LINK;
    const insertMode:InsertMode = dropData.isAttachmentOfCurrentWp() ? InsertMode.ATTACHMENT : insertAlternative;

    description.insertWebLink(insertUrl, insertMode);
    description.save();
  }

  protected openDetailsView(wpId:string):void {
    const stateName = this.$state.current.name as string;
    if (stateName.indexOf('work-packages.list') > -1 &&
        !this.wpEditModeState.active &&
        this.$state.params['workPackageId'] !== wpId) {
      this.loadingIndicator.mainPage = this.$state.go(this.keepTab.currentDetailsState, {
        workPackageId: wpId
      });
    }
  }

  protected prevDefault(evt:DragEvent):void {
    evt.preventDefault();
    evt.stopPropagation();
  }

  protected highlightDroppable = (evt:JQueryEventObject) => {
    // use the browser's native implementation for showing the user
    // that one can drop data on this area
    (evt.originalEvent as DragEvent).dataTransfer.dropEffect = 'copy';
    if (!this.$element.hasClass('is-droppable')) {
      this.$element.addClass('is-droppable');
    }
  };

  protected removeHighlight = () => {
    this.$element.removeClass('is-droppable');
  };
}

interface IAttachmentScope extends ng.IScope {
  workPackage:WorkPackageResourceInterface;
}

function wpAttachmentsFormattable() {
  return {
    bindToController: true,
    controller: WpAttachmentsFormattableController,
    link: (scope:IAttachmentScope,
           element:ng.IAugmentedJQuery,
           attrs:ng.IAttributes,
           controllers:[WorkPackageSingleViewController, WorkPackageEditFormController]) => {
      // right now the attachments directive will only work in combination with either
      // the wpSingleView or the wpEditForm directive
      // else the drop handler will fail because of a missing reference to the current wp
      if (angular.isUndefined(controllers[0] && angular.isUndefined(controllers[1]))) {
        return;
      }

      scope.workPackage = !controllers[0] ? controllers[1].workPackage : controllers[0].workPackage;
    },
    require: ['?^wpSingleView', '?^wpEditForm'],
    restrict: 'A'
  };
}

openprojectModule.directive('wpAttachmentsFormattable', wpAttachmentsFormattable);
