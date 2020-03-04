import {Injectable} from "@angular/core";
import {OpenprojectIFCModelsModule} from "core-app/modules/ifc_models/openproject-ifc-models.module";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {GonService} from "core-app/modules/common/gon/gon.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";

export interface IFCPermissionMap {
  manage_ifc_models:boolean;
  manage_bcf:boolean;
}

export interface IFCGonDefinition {
  models:IfcModelDefinition[];
  shown_models:number[];
  projects:{ id:string, name:string }[];
  xkt_attachment_ids:{ [id:number]:number };
  metadata_attachment_ids:{ [id:number]:number };
  permissions:IFCPermissionMap;
}

export interface IfcModelDefinition {
  name:string;
  id:number;
  default:boolean;
  saoEnabled:boolean;
}

@Injectable({providedIn: OpenprojectIFCModelsModule})
export class IfcModelsDataService {

  constructor(readonly paths:PathHelperService,
              readonly currentProjectService:CurrentProjectService,
              readonly gon:GonService) {
  }

  public get models():IfcModelDefinition[] {
    return this.gonIFC.models;
  }

  public get shownModels():number[] {
    return this.gonIFC.shown_models;
  }

  public isSingleModel() {
    return this.shownModels.length === 1;
  }

  public isDefaults():boolean {
    return !this
      .models
      .find(item => item.default && this.shownModels.indexOf(item.id) === -1);
  }

  public get manageIFCPath() {
    return this.paths.ifcModelsPath(this.currentProjectService.identifier!);
  }

  public allowed(permission:keyof IFCPermissionMap):boolean {
    return !!this.gonIFC.permissions[permission];
  }

  private get gonIFC():IFCGonDefinition {
    return (this.gon.get('ifc_models') as IFCGonDefinition);
  }
}