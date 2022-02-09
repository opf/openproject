import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  ChangeDetectionStrategy,
  HostBinding,
  Component,
  Input,
  EventEmitter,
  Output,
} from '@angular/core';
import { IProjectData } from './project-data';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';

@Component({
  selector: '[op-project-list]',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './project-list.component.html',
  styleUrls: ['./project-list.component.sass'],
})
export class OpProjectListComponent {
  @HostBinding('class.spot-list') classNameList = true;
  @HostBinding('class.op-project-list') className = true;

  @Output('update') onUpdateSelected = new EventEmitter<string[]>();

  @Input() projects:IProjectData[] = [];
  @Input() selected:string[] = [];

  public get currentProjectHref() {
    return this.currentProjectService.apiv3Path;
  }

  constructor(
    readonly I18n:I18nService,
    readonly currentProjectService:CurrentProjectService,
  ) { }

  public updateSelected(selected:string[]) {
    this.onUpdateSelected.emit(selected);
  }

  public isChecked(href:string) {
    return this.selected.includes(href);
  }

  public changeSelected(href:string) {
    const checked = this.isChecked(href);
    if (checked) {
      this.updateSelected(this.selected.filter(selectedHref => selectedHref !== href));
    } else {
      this.updateSelected([
        ...this.selected,
        href,
      ]);
    }
  }

  public selectRecursively(children:IProjectData[]) {
    const selected = [...this.selected];
    for (const child of children) {
      if (!this.isChecked(child.href)) {
        selected.push(child.href);
      }

      this.selectRecursively(child.children);
    }

    this.updateSelected(selected);
  }
}
