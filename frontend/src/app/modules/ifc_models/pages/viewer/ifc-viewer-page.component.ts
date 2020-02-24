import {Component, Injector, HostBinding, ChangeDetectionStrategy} from "@angular/core";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {GonService} from "core-app/modules/common/gon/gon.service";
import {WorkPackagesViewBase} from "core-app/modules/work_packages/routing/wp-view-base/work-packages-view.base";

@Component({
  templateUrl: './ifc-viewer-page.component.html',
  styleUrls: ['./ifc-viewer-page.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class IFCViewerPageComponent extends WorkPackagesViewBase {
  text = {
    title: this.I18n.t('js.ifc_models.models.default'),
    manage: this.I18n.t('js.ifc_models.models.manage'),
    delete: this.I18n.t('js.button_delete'),
    edit: this.I18n.t('js.button_edit'),
    areYouSure: this.I18n.t('js.text_are_you_sure')
  };

  constructor(readonly paths:PathHelperService,
              readonly gon:GonService,
              readonly injector:Injector) {
    super(injector);
  }

  @HostBinding('class')
  get gridTemplateAreas() {
    if (this.$state.includes('bim.space.list')) {
      return '-list';
    } else if (this.$state.includes('bim.space.*.model')) {
      return '-viewer';
    } else {
      return '-split';
    }
  }

  public get title() {
    if (this.$state.includes('bim.space.defaults')) {
      return this.I18n.t('js.ifc_models.models.default');
    } else {
      return this.gonIFC['models'][0]['name'];
    }
  }

  public get manageIFCPath() {
    return this.paths.ifcModelsPath(this.projectIdentifier!);
  }

  public get manageAllowed() {
    return this.gonIFC.permissions.manage;
  }

  private get gonIFC() {
    return (this.gon.get('ifc_models') as any);
  }

  protected set loadingIndicator(promise:Promise<unknown>) {
    // TODO: do something useful
  }

  public refresh(visibly:boolean, firstPage:boolean):Promise<unknown> {
    // TODO: do something useful
    return this.loadingIndicator =
      this.wpListService.loadCurrentQueryFromParams(this.projectIdentifier);
  }
}
