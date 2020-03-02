import {Injectable} from "@angular/core";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {GonService} from "core-app/modules/common/gon/gon.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";

export interface IfcModelDefinition {
  name:string;
  id:string;
  saoEnabled:boolean;
}

@Injectable()
export class IfcModelsDataService {

  constructor(readonly paths:PathHelperService,
              readonly currentProjectService:CurrentProjectService,
              readonly gon:GonService) {
  }

  public get models():IfcModelDefinition[] {
    return this.gonIFC['models'];
  }

  public get manageIFCPath() {
    return this.paths.ifcModelsPath(this.currentProjectService.identifier!);
  }

  public get manageAllowed() {
    return this.gonIFC.permissions.manage;
  }

  private get gonIFC() {
    return (this.gon.get('ifc_models') as any);
  }
}