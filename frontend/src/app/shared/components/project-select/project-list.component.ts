import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  ChangeDetectionStrategy,
  HostBinding,
  Component,
  Input,
  forwardRef,
} from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';
import { ID } from '@datorama/akita';
import { IProjectData } from './project-select.component';

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
  @Input('selected') public _selected:ID[] = [];

  public get selected():ID[] {
    return this._selected;
  }

  public set selected(selected:ID[]) {
    this._selected = selected;
    this.onChange(selected);
    this.onTouched(selected);
  }

  constructor(
    readonly I18n:I18nService,
  ) { }

  public isChecked(id:ID) {
    return this.selected.includes(id);
  }

  public changeSelected(id:ID) {
    const checked = this.isChecked(id);
    if (checked) {
      this.selected = this.selected.filter(selectedID => selectedID !== id);
    } else {
      this.selected = [
        ...this.selected,
        id,
      ];
    }
  }

  public selectRecursively(children:IProjectData[]) {
    for (const child of children) {
      if (!this.isChecked(child.id)) {
        this.selected = [
          ...this.selected,
          child.id,
        ];
      }

      this.selectRecursively(child.children);
    }
  }

  public writeValue(selected:ID[]) {
    if (!Array.isArray(selected)) {
      return;
    }
    this.selected = selected;
  }

  public onChange = (_:ID[]) => {};
  public onTouched = (_:ID[]) => {};

  public registerOnChange(fn:any) {
    this.onChange = fn;
  }

  public registerOnTouched(fn:any) {
    this.onTouched = fn;
  }
}
