import {ChangeDetectionStrategy, ChangeDetectorRef, Component, Injector, OnInit} from "@angular/core";

@Component({
  templateUrl: './cdk-drag-portal-body.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class CdkDragPortalBody {
  constructor(private readonly injector:Injector,
              private readonly cdRef:ChangeDetectorRef) {
  }
}
