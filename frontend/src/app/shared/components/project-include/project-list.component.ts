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
import SpotDropAlignmentOption from 'core-app/spot/drop-alignment-options';

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

  @Input() root:boolean = false;

  @Input() projects:IProjectData[] = [];

  @Input() selected:string[] = [];

  @Input() searchText = '';

  @Input() includeSubprojects = false;

  @Input() parentChecked = false;

  public get currentProjectHref():string|null {
    return this.currentProjectService.apiv3Path;
  }

  public text = {
    include_all_selected: this.I18n.t('js.include_projects.tooltip.include_all_selected'),
    current_project: this.I18n.t('js.include_projects.tooltip.current_project'),
  };

  constructor(
    readonly I18n:I18nService,
    readonly currentProjectService:CurrentProjectService,
  ) { }

  public isDisabled(project:IProjectData):boolean {
    return project.href === this.currentProjectHref || (this.includeSubprojects && this.parentChecked);
  }

  public updateSelected(selected:string[]):void {
    this.update.emit(selected);
  }

  public isChecked(href:string):boolean {
    return this.selected.includes(href);
  }

  public changeSelected(project:IProjectData):void {
    const { href } = project;
    const checked = this.isChecked(href);
    const disabled = this.isDisabled(project);

    if (disabled) {
      return;
    }

    if (checked) {
      this.updateSelected(this.selected.filter((selectedHref) => selectedHref !== href));
    } else {
      this.updateSelected([
        ...this.selected,
        href,
      ]);
    }
  }

  public getAlignment(project:IProjectData, isFirst:boolean, isLast:boolean):SpotDropAlignmentOption {
    if (this.root && isFirst) {
      if (isLast && !project.children.length) {
        return SpotDropAlignmentOption.RightCenter;
      }
       
      return SpotDropAlignmentOption.BottomLeft;
    }

    return SpotDropAlignmentOption.TopLeft;
  }
}
