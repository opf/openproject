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
import { SearchableProjectListService } from 'core-app/shared/components/searchable-project-list/searchable-project-list.service';
import { IProjectData } from 'core-app/shared/components/searchable-project-list/project-data';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';

@Component({
  selector: '[op-header-project-select-list]',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './header-project-select-list.component.html',
  styleUrls: ['./header-project-select-list.component.sass'],
})
export class OpHeaderProjectSelectListComponent {
  @HostBinding('class.spot-list') classNameList = true;

  @HostBinding('class.op-header-project-select-list') className = true;

  @Output() update = new EventEmitter<string[]>();

  @Input() @HostBinding('class.op-header-project-select-list--root') root = false;

  @Input() projects:IProjectData[] = [];

  @Input() searchText = '';

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

  extendedProjectUrl(projectId:string):string {
    const currentMenuItem = document.querySelector('meta[name="current_menu_item"]') as HTMLMetaElement;
    const url = this.pathHelper.projectPath(projectId);

    if (!currentMenuItem) {
      return url;
    }

    return `${url}?jump=${encodeURIComponent(currentMenuItem.content)}`;
  }
}
