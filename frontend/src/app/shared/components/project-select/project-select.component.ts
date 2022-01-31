import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  ChangeDetectionStrategy,
  Component,
} from '@angular/core';
import { ProjectsResourceService } from 'core-app/core/state/projects/projects.service';

@Component({
  selector: 'op-project-select',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './project-select.component.html',
  styleUrls: ['./project-select.component.sass'],
})
export class OpProjectSelectComponent {
  public open = false;
  public searchText = '';
  public includeSubProjects = false;
  public selectedProjects:string[] = [];

  constructor(
    readonly I18n:I18nService,
    readonly projectsResourceService:ProjectsResourceService,
  ) { }

  public searchProjects() {
    console.log(this.searchText);
  }
  public clearSelection() {}
  public save() {}
}
