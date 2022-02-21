import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  ChangeDetectionStrategy,
  Component,
  EventEmitter,
  HostBinding,
  Input,
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

  @Output() update = new EventEmitter<string[]>();

  @Input() projects:IProjectData[] = [];

  @Input() selected:string[] = [];

  public get currentProjectHref():string|null {
    return this.currentProjectService.apiv3Path;
  }

  constructor(
    readonly I18n:I18nService,
    readonly currentProjectService:CurrentProjectService,
  ) { }

  public updateSelected(selected:string[]):void {
    this.update.emit(selected);
  }

  public isChecked(href:string):boolean {
    return this.selected.includes(href);
  }

  public changeSelected(href:string):void {
    const checked = this.isChecked(href);
    if (checked) {
      this.updateSelected(this.selected.filter((selectedHref) => selectedHref !== href));
    } else {
      this.updateSelected([
        ...this.selected,
        href,
      ]);
    }
  }
}
