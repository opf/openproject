import { Component, OnInit, ViewChild, ViewEncapsulation } from "@angular/core";
import { OpDynamicFormComponent } from "core-app/modules/common/dynamic-forms/components/op-dynamic-form/op-dynamic-form.component";

export const backlogsPageComponentSelector = 'op-backlogs-page';

@Component({
  selector: backlogsPageComponentSelector,
  // Empty wrapper around legacy backlogs for CSS loading
  // that got removed in the Rails assets pipeline
  encapsulation: ViewEncapsulation.None,
  template: `
    <op-dynamic-form [formId]="formId" [projectId]="projectId" [typeHref]="typeHref" *ngIf="showForm" #dynamicForm>
    </op-dynamic-form>
  `,
  styleUrls: [
    './styles/backlogs.sass'
  ]
})
export class BacklogsPageComponent implements OnInit {
  formId = "117";
  projectId = "1";
  typeHref = "/api/v3/types/1";
  showForm = true;

  @ViewChild(OpDynamicFormComponent) dynamicForm:OpDynamicFormComponent;

  ngOnInit() {
    //document.getElementById('projected-content')!.hidden = false;
  }
}