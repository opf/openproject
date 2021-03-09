import { AbstractWidgetComponent } from "core-app/modules/grids/widgets/abstract-widget.component";
import { ChangeDetectionStrategy, Component, Injector, OnInit, ChangeDetectorRef } from '@angular/core';
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { TimezoneService } from "core-components/datetime/timezone.service";
import { NewsResource } from "core-app/modules/hal/resources/news-resource";
import { CurrentProjectService } from "core-components/projects/current-project.service";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";
import { Apiv3ListParameters } from "core-app/modules/apiv3/paths/apiv3-list-resource.interface";

@Component({
  templateUrl: './news.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WidgetNewsComponent extends AbstractWidgetComponent implements OnInit {
  public text = {
    at: this.i18n.t('js.grid.widgets.news.at'),
    noResults: this.i18n.t('js.grid.widgets.news.no_results'),
    addedBy: (news:NewsResource) => this.i18n.t('js.label_added_time_by',
      { author: this.newsAuthorName(news), age: this.newsCreated(news), authorLink: this.newsAuthorPath(news) })
  };

  public entries:NewsResource[] = [];
  private entriesLoaded = false;

  constructor(

    readonly pathHelper:PathHelperService,
    readonly i18n:I18nService,
    protected readonly injector:Injector,
    readonly timezone:TimezoneService,
    readonly currentProject:CurrentProjectService,
    readonly apiV3Service:APIV3Service,
    readonly cdr:ChangeDetectorRef
  ) {
    super(i18n, injector);
  }

  ngOnInit() {
    this
      .apiV3Service
      .news
      .list(this.newsDmParams)
      .subscribe(collection => this.setupNews(collection.elements));
  }

  public setupNews(news:any[]) {

    this.entries = news;
    this.entriesLoaded = true;
    this.cdr.detectChanges();
  }

  public get isEditable() {
    return false;
  }

  public newsPath(news:NewsResource) {

    return this.pathHelper.newsPath(news.id!);
  }

  public newsProjectPath(news:NewsResource) {
    return this.pathHelper.projectPath(news.project?.idFromLink);
  }

  public newsProjectName(news:NewsResource) {
    return news.project?.name;
  }

  public newsAuthorName(news:NewsResource) {
    return news.author?.name;
  }

  public newsAuthorPath(news:NewsResource) {
    return this.pathHelper.userPath(news.author?.id);

  }

  public newsCreated(news:NewsResource) {
    return this.timezone.formattedDatetime(news.createdAt);
  }

  public get noEntries() {
    return !this.entries.length && this.entriesLoaded;
  }

  private get newsDmParams() {
    const params:Apiv3ListParameters = {
      sortBy: [['created_at', 'desc']],
      pageSize: 3
    };

    if (this.currentProject.id) {
      params['filters'] = [['project_id', '=', [this.currentProject.id]]];
    }

    return params;
  }
}
