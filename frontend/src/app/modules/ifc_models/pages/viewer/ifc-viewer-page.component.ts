import {Component} from "@angular/core";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {WorkPackageTableConfigurationObject} from "core-components/wp-table/wp-table-configuration";
import { StateService } from '@uirouter/core';
import {GonService} from "core-app/modules/common/gon/gon.service";

@Component({
  templateUrl: './ifc-viewer-page.component.html',
  styleUrls: ['./ifc-viewer-page.component.sass']
})
export class IfcViewerPageComponent {
  public text = {
    title: this.i18n.t('js.ifc_models.models.default'),
    manage: this.i18n.t('js.ifc_models.models.manage'),
    delete: this.i18n.t('js.button_delete'),
    edit: this.i18n.t('js.button_edit'),
    areYouSure: this.i18n.t('js.text_are_you_sure')
  };

  constructor(readonly state:StateService,
              readonly i18n:I18nService,
              readonly paths:PathHelperService,
              readonly currentProject:CurrentProjectService,
              readonly gon:GonService) {
  }

  public get title() {
    if (this.state.current.name === 'bim_defaults') {
      return this.i18n.t('js.ifc_models.models.default');
    } else {
      return this.gonIFC['models'][0]['name'];
    }
  }

  public get projectIdentifier() {
    return this.currentProject.identifier!;
  }

  public get manageIFCPath() {
    return this.paths.ifcModelsPath(this.projectIdentifier);
  }

  public get viewerActive() {
    return this.state.includes('bim.defaults') || this.state.includes('bim.show');
  }

  public get tableActive() {
    return this.state.includes('bim.list') || this.state.includes('bim.*.split');
  }

  public get manageAllowed() {
    return this.gonIFC.permissions.manage;
  }

  private get gonIFC() {
    return (this.gon.get('ifc_models') as any)
  }
}
