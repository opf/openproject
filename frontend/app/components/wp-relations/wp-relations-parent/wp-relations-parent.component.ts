import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {WorkPackageRelationsHierarchyService} from '../wp-relations-hierarchy/wp-relations-hierarchy.service';
import {WorkPackageCacheService} from '../../work-packages/work-package-cache.service';
import {WorkPackageNotificationService} from '../../wp-edit/wp-notification.service';
import {PathHelperService} from 'core-components/common/path-helper/path-helper.service';
import {Component, ElementRef, Inject, Input, OnDestroy, OnInit} from '@angular/core';
import {componentDestroyed} from 'ng2-rx-componentdestroyed';
import {I18nToken} from 'core-app/angular4-transition-utils';

@Component({
  selector: 'wp-relation-parent',
  template: require('!!raw-loader!./wp-relations-parent.html')
})
export class WpRelationParentComponent implements OnInit, OnDestroy {
  @Input() public workPackage:WorkPackageResourceInterface;
  public showEditForm:boolean = false;
  public canModifyHierarchy:boolean = false;
  public selectedWpId:string|null = null;

  constructor(readonly elementRef:ElementRef,
              readonly wpRelationsHierarchyService:WorkPackageRelationsHierarchyService,
              readonly wpCacheService:WorkPackageCacheService,
              readonly wpNotificationsService:WorkPackageNotificationService,
              readonly PathHelper:PathHelperService,
              @Inject(I18nToken) readonly I18n:op.I18n) {
  }

  public text = {
    add_parent:this.I18n.t('js.relation_buttons.add_parent'),
    change_parent:this.I18n.t('js.relation_buttons.change_parent'),
    remove_parent:this.I18n.t('js.relation_buttons.remove_parent'),
    remove:this.I18n.t('js.relation_buttons.remove'),
    parent:this.I18n.t('js.relation_labels.parent'),
  };

  ngOnDestroy() {
    // Nothing to do
  }

  ngOnInit() {
    this.canModifyHierarchy = !!this.workPackage.changeParent;

    this.wpCacheService.state(this.workPackage.id)
      .values$()
      .takeUntil(componentDestroyed(this))
      .subscribe(wp => this.workPackage = wp);
  }

  public updateSelectedId(workPackageId:string) {
    this.selectedWpId = workPackageId;
  }

  public changeParent() {
    if (_.isNil(this.selectedWpId)) {
      return;
    }

    const newParentId = this.selectedWpId;
    this.showEditForm = false;
    this.selectedWpId = null;

    this.wpRelationsHierarchyService.changeParent(this.workPackage, newParentId)
      .then((updatedWp:WorkPackageResourceInterface) => {
        setTimeout(() => angular.element('#hierarchy--parent').focus());
      })
      .catch((err:any) => this.wpNotificationsService.handleErrorResponse(err, this.workPackage));
  }

  public get relationReady() {
    return this.workPackage.parent && this.workPackage.parent.$loaded;
  }

  public removeParent() {
    this.wpRelationsHierarchyService
      .removeParent(this.workPackage)
      .then(() => {
        this.wpNotificationsService.showSave(this.workPackage);
        setTimeout(() => {
          angular.element('#hierarchy--add-parent').focus();
        });
      });
  }
}
