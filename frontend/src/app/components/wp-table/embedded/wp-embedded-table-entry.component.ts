import {Component, ElementRef, Input, OnInit} from '@angular/core';
import {DynamicBootstrapper} from "core-app/globals/dynamic-bootstrapper";

@Component({
  selector: 'wp-embedded-table-entry',
  template: `
    <ng-container wp-isolated-query-space>
      <wp-embedded-table [queryProps]="queryProps"
                         [initialLoadingIndicator]="initialLoadingIndicator"
                         [configuration]="configuration">
      </wp-embedded-table>
    </ng-container>
  `
})
export class WorkPackageEmbeddedTableEntryComponent implements OnInit {
  @Input() public queryProps:any;
  @Input() public configuration:any;
  @Input() public initialLoadingIndicator:boolean = true;

  constructor(readonly elementRef:ElementRef) {
  }

  ngOnInit() {
    const element = this.elementRef.nativeElement;

    if (element.getAttribute('query-props')) {
      this.getInputsFromData(element);
    }
  }

  private getInputsFromData(element:HTMLElement) {
    this.queryProps = JSON.parse(element.getAttribute('query-props')!);
    this.configuration = JSON.parse(element.getAttribute('configuration')!);
  }
}

DynamicBootstrapper.register({ selector: 'wp-embedded-table-entry', cls: WorkPackageEmbeddedTableEntryComponent });
