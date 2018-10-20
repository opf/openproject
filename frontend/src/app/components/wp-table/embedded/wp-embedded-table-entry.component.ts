import {Component, ElementRef, OnInit} from '@angular/core';
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";

@Component({
  selector: 'wp-embedded-table-entry',
  template: `
    <wp-embedded-table [queryProps]="queryProps"
                       [configuration]="configuration">
    </wp-embedded-table>
  `
})
export class WorkPackageEmbeddedTableEntryComponent implements OnInit {
  public queryProps:any;
  public configuration:any;

  constructor(readonly elementRef:ElementRef) {
  }

  ngOnInit() {
    const element = this.elementRef.nativeElement;
    this.queryProps = JSON.parse(element.getAttribute('query-props'));
    this.configuration = JSON.parse(element.getAttribute('configuration'));
  }
}

DynamicBootstrapper.register({ selector: 'wp-embedded-table-entry', cls: WorkPackageEmbeddedTableEntryComponent });
