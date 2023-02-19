import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  ChangeDetectionStrategy,
  Component,
  EventEmitter,
  HostBinding,
  Input,
  Output,
} from '@angular/core';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import SpotDropAlignmentOption from 'core-app/spot/drop-alignment-options';
import { IProjectData } from 'core-app/shared/components/searchable-project-list/project-data';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { SearchableProjectListService } from 'core-app/shared/components/searchable-project-list/searchable-project-list.service';

@Component({
  selector: '[op-project-include-list]',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './project-include-list.component.html',
  styleUrls: ['./project-include-list.component.sass'],
})
export class OpProjectIncludeListComponent {
  @HostBinding('class.spot-list') classNameList = true;

  @HostBinding('class.op-project-include-list') className = true;

  @Output() update = new EventEmitter<string[]>();

  @Input() @HostBinding('class.op-project-include-list--root') root = false;

  @Input() projects:IProjectData[] = [];

  @Input() selected:string[] = [];

  @Input() searchText = '';

  @Input() includeSubprojects = false;

  @Input() parentChecked = false;

  public get currentProjectHref():string|null {
    return this.currentProjectService.apiv3Path;
  }

  public text = {
    does_not_match_search: this.I18n.t('js.include_projects.tooltip.does_not_match_search'),
    include_all_selected: this.I18n.t('js.include_projects.tooltip.include_all_selected'),
    current_project: this.I18n.t('js.include_projects.tooltip.current_project'),
  };

  constructor(
    readonly I18n:I18nService,
    readonly currentProjectService:CurrentProjectService,
    readonly pathHelper:PathHelperService,
    readonly searchableProjectListService:SearchableProjectListService,
  ) { }

  public updateList(selected:string[]):void {
    this.update.emit(selected);
  }

  public isChecked(href:string):boolean {
    return this.selected.includes(href);
  }

  public changeSelected(project:IProjectData):void {
    if (project.disabled) {
      return;
    }

    const { href } = project;
    const checked = this.isChecked(href);

    if (checked) {
      this.updateList(this.selected.filter((selectedHref) => selectedHref !== href));
    } else {
      this.updateList([
        ...this.selected,
        href,
      ]);
    }
  }

  public getTooltipAlignment(isFirst:boolean):SpotDropAlignmentOption {
    if (!this.root || !isFirst) {
      return SpotDropAlignmentOption.TopLeft;
    }

    return SpotDropAlignmentOption.BottomLeft;
  }

  extendedProjectUrl(projectId:string):string {
    const currentMenuItem = document.querySelector('meta[name="current_menu_item"]') as HTMLMetaElement;
    const url = this.pathHelper.projectPath(projectId);

    if (!currentMenuItem) {
      return url;
    }

    return `${url}?jump=${encodeURIComponent(currentMenuItem.content)}`;
  }
}
