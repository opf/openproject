import {Component, Injector, Input, OnDestroy, OnInit} from "@angular/core";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {StateService} from "@uirouter/core";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";


export type ViewPointOriginal = { id:string, file_name:string };
export type ViewPoint = { id:string, fileName:string, fullPath:string };

@Component({
  selector: 'bcf-wp-single-view',
  templateUrl: './bcf-wp-single-view.component.html',
  styleUrls: ['./bcf-wp-single-view.component.sass']
})

export class BcfWpSingleViewComponent implements OnInit, OnDestroy {
  @Input() workPackage:WorkPackageResource;
  private _viewpoints:ViewPoint[];

  public get viewpoints():ViewPoint[] {
    return this._viewpoints;
  }

  public set viewpoints(viewPoints:ViewPoint[]) {
    this._viewpoints = viewPoints;
  }

  public text = {
  };

  constructor(public readonly state:StateService,
              private readonly I18n:I18nService,
              private readonly injector:Injector,
              private readonly pathHelper:PathHelperService) {
  }

  ngOnInit():void {
    this.viewpoints = this.workPackage.bcf.viewpoints.map((vp:ViewPointOriginal):ViewPoint => {
      return {
        id:       vp.id,
        fileName: vp.file_name,
        fullPath: this.pathHelper.attachmentDownloadPath(vp.id, vp.file_name)
      };
    });
  }

  ngOnDestroy():void {
    // Nothing to do.
  }
}
