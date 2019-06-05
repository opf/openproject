import {AbstractWidgetComponent} from "core-app/modules/grids/widgets/abstract-widget.component";
import {Component, OnInit, SecurityContext} from '@angular/core';
import {DocumentResource} from "../../../../../../../modules/documents/frontend/module/hal/resources/document-resource";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {CollectionResource} from "core-app/modules/hal/resources/collection-resource";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {TimezoneService} from "core-components/datetime/timezone.service";
import {DomSanitizer} from '@angular/platform-browser';

@Component({
  templateUrl: './documents.component.html',
})
export class WidgetDocumentsComponent extends AbstractWidgetComponent implements OnInit {
  public text = {
    title: this.i18n.t('js.grid.widgets.documents.title'),
    noResults: this.i18n.t('js.grid.widgets.documents.no_results'),
  };

  public entries:DocumentResource[] = [];
  private entriesLoaded = false;

  constructor(readonly halResource:HalResourceService,
              readonly pathHelper:PathHelperService,
              readonly i18n:I18nService,
              readonly timezone:TimezoneService,
              readonly domSanitizer:DomSanitizer) {
    super(i18n);
  }

  ngOnInit() {
    let orders = JSON.stringify([['created_on', 'desc']]);

    let url = `${this.pathHelper.api.v3.apiV3Base}/documents?sortBy=${orders}&pageSize=10`;

    this.halResource
      .get<CollectionResource>(url)
      .toPromise()
      .then((collection) => {
        this.entries = collection.elements as DocumentResource[];
        this.entriesLoaded = true;
      });
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
}
