import {InsertMode, ViewMode} from './wp-attachments-formattable.enums';
import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {KeepTabService} from '../../wp-panels/keep-tab/keep-tab.service';
import {openprojectModule} from '../../../angular-modules';
import {WorkPackageCacheService} from '../work-package-cache.service';
import {MarkupModel} from './models/markup-model';
import {EditorModel} from './models/editor-model';
import {PasteModel} from './models/paste-model';
import {WorkPackageFieldModel} from './models/work-package-field-model';
import {DropModel} from './models/drop-model';
import {SingleAttachmentModel} from './models/single-attachment';
import {WorkPackageSingleViewController} from '../wp-single-view/wp-single-view.directive';
import {CommentFieldDirectiveController} from '../work-package-comment/work-package-comment.directive';
import {UploadFile} from '../../api/op-file-upload/op-file-upload.service';

export class WpAttachmentsFormattableController {
  constructor(protected $scope:ng.IScope,
              protected $element:ng.IAugmentedJQuery,
              protected $rootScope:ng.IRootScopeService,
              protected $location:ng.ILocationService,
              protected wpCacheService:WorkPackageCacheService,
              protected $timeout:ng.ITimeoutService,
              protected $q:ng.IQService,
              protected $state:ng.ui.IStateService,
              protected loadingIndicator:any,
              protected keepTab:KeepTabService) {

    $element.on('paste', this.handlePaste);
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

    const [, editor] = this.getEditor();

    const originalEvent = (evt.originalEvent as DragEvent);
    const workPackage:WorkPackageResourceInterface = this.$scope.workPackage;
    const dropData:DropModel = new DropModel(this.$location,
      originalEvent.dataTransfer,
      workPackage);

    if (angular.isUndefined(dropData.webLinkUrl) && angular.isUndefined(dropData.files)) {
      return;
    }

    if (dropData.isUpload) {
      this.uploadAndInsert(dropData.files, editor);
    } else {
      this.insertUrls(dropData, editor);
    }
    this.openDetailsView(workPackage.id.toString());
    this.removeHighlight();
  }

  public handlePaste = (evt:JQueryEventObject):boolean => {
    const [viewMode, editor] = this.getEditor();

    if (viewMode !== ViewMode.EDIT) {
      return true;
    }

    const pasteEvt = (evt.originalEvent as ClipboardEvent);
    const pasteData = new PasteModel(pasteEvt.clipboardData);
    const count = pasteData.files.length;

    if (count === 0) {
      return true;
    }

    this.uploadAndInsert(pasteData.files, editor);

    evt.preventDefault();
    evt.stopPropagation();
    return false;
  }

  /**
   * Get the editor model for the current view mode.
   * This is either the editing model (open textarea field), or the closed field model.
   */
  protected getEditor():[ViewMode, EditorModel | WorkPackageFieldModel] {
    const textarea:ng.IAugmentedJQuery = this.$element.find('textarea');

    let viewMode;
    let model;

    if (textarea.length > 0) {
      viewMode = ViewMode.EDIT;
      model = new EditorModel(textarea, new MarkupModel());
    } else {
      viewMode = ViewMode.SHOW;
      model = new WorkPackageFieldModel(this.$scope.workPackage, this.$scope.attribute, new MarkupModel());
    }

    return [viewMode, model];
  }

  protected uploadAndInsert(files:UploadFile[], model:EditorModel | WorkPackageFieldModel) {
    const wp = this.$scope.workPackage as WorkPackageResourceInterface;
    if (wp.isNew) {
      return this.insertDelayedAttachments(files, model, wp);
    }

    wp
      .uploadAttachments(files)
      .then(attachments => attachments.elements)
      .then((updatedAttachments:any) => {
        if (angular.isUndefined(updatedAttachments)) {
          return;
        }
        updatedAttachments = this.sortAttachments(updatedAttachments);

        if (files.length === 1) {
          this.insertSingleAttachment(updatedAttachments, model);
        }
        else if (files.length > 1) {
          this.insertMultipleAttachments(files.length, updatedAttachments, model);
        }

        model.save();
      });
  }

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

  protected insertMultipleAttachments(count:number, updatedAttachments:any, description:any):void {
    for (let i:number = updatedAttachments.length - 1;
         i >= updatedAttachments.length - count;
         i--) {
      description.insertAttachmentLink(
        updatedAttachments[i].downloadLocation.href,
        InsertMode.ATTACHMENT,
        true);
    }
  }

  protected insertDelayedAttachments(files:UploadFile[], description:any, workPackage:WorkPackageResourceInterface):void {
    for (var i = 0; i < files.length; i++) {
      var currentFile = new SingleAttachmentModel(files[i]);
      var insertMode = currentFile.isAnImage ? InsertMode.INLINE : InsertMode.ATTACHMENT;
      const name = files[i].customName || files[i].name;

      description.insertAttachmentLink(name.replace(/ /g, '_'), insertMode, true);
      workPackage.pendingAttachments.push((files[i]));
    }

    description.save();
  }

  protected insertUrls(dropData:DropModel, description:any):void {
    const insertUrl:string = dropData.isAttachmentOfCurrentWp() ? dropData.removeHostInformationFromUrl() : dropData.webLinkUrl;
    const insertAlternative:InsertMode = dropData.isWebImage() ? InsertMode.INLINE : InsertMode.LINK;
    const insertMode:InsertMode = dropData.isAttachmentOfCurrentWp() ? InsertMode.ATTACHMENT : insertAlternative;

    description.insertWebLink(insertUrl, insertMode);
    description.save();
  }

  protected openDetailsView(wpId:string):void {
    const stateName = this.$state.current.name as string;
    if (stateName.indexOf('work-packages.list') > -1 &&
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

function wpAttachmentsFormattable() {
  return {
    bindToController: true,
    controller: WpAttachmentsFormattableController,
    link: (scope:ng.IScope,
           element:ng.IAugmentedJQuery,
           attrs:ng.IAttributes,
           controllers:[WorkPackageSingleViewController, CommentFieldDirectiveController]) => {
      scope.workPackage = (controllers[0] || controllers[1]).workPackage;
      scope.attribute = scope.$eval(attrs.fieldName);
    },
    require: ['?^wpSingleView', '?^workPackageComment'],
    restrict: 'A'
  };
}

openprojectModule.directive('wpAttachmentsFormattable', wpAttachmentsFormattable);
