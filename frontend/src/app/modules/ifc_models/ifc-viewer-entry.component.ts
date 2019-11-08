import {Component, ElementRef, Input, OnInit} from '@angular/core';
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";

@Component({
  selector: 'ifc-viewer-entry',
  template: `
    <ifc-viewer [ifcModelId]="ifcModelId"
                [xktFileUrl]="xktFileUrl"
                [metadataFileUrl]="metadataFileUrl"></ifc-viewer>
  `
})
export class IFCViewerEntryComponent implements OnInit {
  constructor(readonly elementRef:ElementRef) {
  }

  public ifcModelId:string;
  public xktFileUrl:string;
  public metadataFileUrl:string;

  ngOnInit() {
    const element = this.elementRef.nativeElement;
    this.ifcModelId = element.dataset.ifcModelId;
    this.xktFileUrl = element.dataset.xktFileUrl;
    this.metadataFileUrl = element.dataset.metadataFileUrl;
  }
}

DynamicBootstrapper.register({ selector: 'ifc-viewer-entry', cls: IFCViewerEntryComponent });
