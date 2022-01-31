import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  ChangeDetectionStrategy,
  Component,
} from '@angular/core';
import {
  FormGroup,
  FormArray,
  FormControl,
} from '@angular/forms';
import { ProjectsResourceService } from 'core-app/core/state/projects/projects.service';

@Component({
  selector: 'op-project-select',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './project-select.component.html',
  styleUrls: ['./project-select.component.sass'],
})
export class OpProjectSelectComponent {
  public open = false;
  public form = new FormGroup({
    query: new FormControl(''),
    includeSubProjects: new FormControl(false),
    selectedProjects: new FormArray([]),
  });

  public get queryControl() { return this.form.get('query'); }
  public get query() { return this.queryControl?.value; }
  public get includeSubProjectsControl() { return this.form.get('includeSubProjectsControl'); }
  public get selectedProjectsControl() { return this.form.get('selectedProjectsControl'); }

  constructor(
    readonly I18n:I18nService,
    readonly projectsResourceService:ProjectsResourceService,
  ) { }

  public searchProjects() {
    console.log(this.query);
    if (!this.query) {
      return;
    }

    this.projectsResourceService
      .search(this.query)
      .subscribe((projects) => {
        console.log(projects);
      });
  }
  public clearSelection() {}
  public save() {}
}
