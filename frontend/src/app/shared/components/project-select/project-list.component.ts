import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  ChangeDetectionStrategy,
  HostBinding,
  Component,
  Input,
  forwardRef,
} from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';
import { IProjectData } from './project-data';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';

@Component({
  selector: '[op-project-list]',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './project-list.component.html',
  styleUrls: ['./project-list.component.sass'],
  providers: [{
    provide: NG_VALUE_ACCESSOR,
    useExisting: forwardRef(() => OpProjectListComponent),
    multi: true,
  }],
})
export class OpProjectListComponent implements ControlValueAccessor {
  @HostBinding('class.spot-list') classNameList = true;
  @HostBinding('class.op-project-list') className = true;

  @Input() projects:IProjectData[] = [];
  @Input('selected') public _selected:string[] = [];

  public get selected():string[] {
    return this._selected;
  }

  public set selected(selected:string[]) {
    this._selected = selected;
    this.onChange(selected);
    this.onTouched(selected);
  }

  public get currentProjectHref() {
    return this.currentProjectService.apiv3Path;
  }

  constructor(
    readonly I18n:I18nService,
    readonly currentProjectService:CurrentProjectService,
  ) { }

  public isChecked(href:string) {
    return this.selected.includes(href);
  }

  public changeSelected(href:string) {
    const checked = this.isChecked(href);
    if (checked) {
      this.selected = this.selected.filter(selectedHref => selectedHref !== href);
    } else {
      this.selected = [
        ...this.selected,
        href,
      ];
    }
  }

  public selectRecursively(children:IProjectData[]) {
    for (const child of children) {
      if (!this.isChecked(child.href)) {
        this.selected = [
          ...this.selected,
          child.href,
        ];
      }

      this.selectRecursively(child.children);
    }
  }

  public trackByProject(_:number, project:IProjectData) {
    return project.href;
  }

  public writeValue(selected:string[]) {
    if (!Array.isArray(selected)) {
      return;
    }
    this.selected = selected;
  }

  public onChange = (_:string[]) => {};
  public onTouched = (_:string[]) => {};

  public registerOnChange(fn:any) {
    this.onChange = fn;
  }

  public registerOnTouched(fn:any) {
    this.onTouched = fn;
  }
}
