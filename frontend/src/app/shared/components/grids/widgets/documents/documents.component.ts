import { AbstractWidgetComponent } from 'core-app/shared/components/grids/widgets/abstract-widget.component';
import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  Injector,
  OnInit,
  SecurityContext,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { DomSanitizer } from '@angular/platform-browser';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { DocumentResource } from '../../../../../../../../modules/documents/frontend/module/hal/resources/document-resource';

@Component({
  templateUrl: './documents.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WidgetDocumentsComponent extends AbstractWidgetComponent implements OnInit {
  public text = {
    noResults: this.i18n.t('js.grid.widgets.documents.no_results'),
    project: this.i18n.t('js.label_project'),
  };

  public entries:DocumentResource[] = [];

  private entriesLoaded = false;

  constructor(readonly halResource:HalResourceService,
    readonly pathHelper:PathHelperService,
    readonly apiV3Service:ApiV3Service,
    readonly i18n:I18nService,
    readonly timezone:TimezoneService,
    readonly domSanitizer:DomSanitizer,
    protected readonly injector:Injector,
    readonly currentProject:CurrentProjectService,
    readonly cdr:ChangeDetectorRef) {
    super(i18n, injector);
  }

  ngOnInit() {
    this.halResource
      .get<CollectionResource>(this.documentsUrl)
      .subscribe((collection) => {
        this.entries = collection.elements as DocumentResource[];
        this.entriesLoaded = true;

        this.cdr.detectChanges();
      });
  }

  public get isEditable() {
    return false;
  }

  public documentPath(document:DocumentResource) {
    return `${this.pathHelper.appBasePath}/documents/${document.id}`;
  }

  public documentCreated(document:DocumentResource) {
    return this.timezone.formattedDatetime(document.createdAt);
  }

  public documentDescription(document:DocumentResource) {
    return this.domSanitizer.sanitize(SecurityContext.HTML, document.description.html);
  }

  public get noEntries() {
    return !this.entries.length && this.entriesLoaded;
  }

  public get documentsUrl() {
    const orders = JSON.stringify([['updated_at', 'desc']]);

    let url = `${this.apiV3Service.documents.toPath()}?sortBy=${orders}&pageSize=10`;

    if (this.currentProject.id) {
      const filters = JSON.stringify([{ project_id: { operator: '=', values: [this.currentProject.id.toString()] } }]);

      url += `&filters=${filters}`;
    }

    return url;
  }
}
