import {Component, Injector, Input, OnDestroy, OnInit} from "@angular/core";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {StateService} from "@uirouter/core";
import {WorkPackageResource} from "core-app/modules/hal/resources/work-package-resource";

@Component({
  selector: 'bcf-wp-single-view',
  templateUrl: './bcf-wp-single-view.component.html',
  styleUrls: ['./bcf-wp-single-view.component.sass']
})

export class BcfWpSingleViewComponent implements OnInit, OnDestroy {
  @Input() workPackage:WorkPackageResource;

  public text = {
  };


  constructor(public readonly state:StateService,
              private readonly I18n:I18nService,
              private readonly injector:Injector) {
  }

  ngOnInit():void {
    // TODO
  }

  ngOnDestroy():void {
    // Nothing to do.
  }
}
