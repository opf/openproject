import {AbstractWidgetComponent} from "core-app/modules/grids/widgets/abstract-widget.component";
import {Component, OnInit, ChangeDetectorRef, Injector, ChangeDetectionStrategy} from '@angular/core';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {TimezoneService} from "core-components/datetime/timezone.service";
import {NewsResource} from "core-app/modules/hal/resources/news-resource";
import {UserCacheService} from "core-components/user/user-cache.service";
import {UserResource} from "core-app/modules/hal/resources/user-resource";
import {NewsDmService} from "core-app/modules/hal/dm-services/news-dm.service";
import {CurrentProjectService} from "core-components/projects/current-project.service";
import {DmListParameter} from "core-app/modules/hal/dm-services/dm.service.interface";

@Component({
  templateUrl: './news.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WidgetNewsComponent extends AbstractWidgetComponent implements OnInit {
  public text = {
    createdBy: this.i18n.t('js.label_created_by'),
    at: this.i18n.t('js.grid.widgets.news.at'),
    noResults: this.i18n.t('js.grid.widgets.news.no_results'),
  };

  public entries:NewsResource[] = [];
  private entriesLoaded = false;

  constructor(readonly halResource:HalResourceService,
              readonly pathHelper:PathHelperService,
              readonly i18n:I18nService,
              protected readonly injector:Injector,
              readonly timezone:TimezoneService,
              readonly userCache:UserCacheService,
              readonly newsDm:NewsDmService,
              readonly currentProject:CurrentProjectService,
              readonly cdr:ChangeDetectorRef) {
    super(i18n, injector);
  }

  ngOnInit() {
    this.newsDm
      .list(this.newsDmParams)
      .then((collection) => {
        this.entries = collection.elements as NewsResource[];
        this.entriesLoaded = true;

        const users_loaded = this.setAuthors();

        Promise.all(users_loaded)
          .then(() => this.cdr.detectChanges());
      });
  }

  public get isEditable() {
    return false;
  }

  public newsPath(news:NewsResource) {
    return this.pathHelper.newsPath(news.id!);
  }

  public newsProjectPath(news:NewsResource) {
    return this.pathHelper.projectPath(news.project.idFromLink);
  }

  public newsProjectName(news:NewsResource) {
    return news.project.name;
  }

  public newsAuthorName(news:NewsResource) {
    return news.author.name;
  }

  public newsAuthorPath(news:NewsResource) {
    return this.pathHelper.userPath(news.author.id);
  }

  public newsCreated(news:NewsResource) {
    return this.timezone.formattedDatetime(news.createdAt);
  }

  public get noEntries() {
    return !this.entries.length && this.entriesLoaded;
  }

  public setAuthors() {
    return this.entries.map((entry) => {
      if (!entry.author) {
        return Promise.resolve();
      }

      return this.userCache
        .require(entry.author.idFromLink)
        .then((user:UserResource) => {
          entry.author = user;
        });
    });
  }

  private get newsDmParams() {
    let params:DmListParameter = { sortBy: [['created_on', 'desc']],
                                   pageSize: 3 };

    if (this.currentProject.id) {
      params['filters'] = [['project_id', '=', [this.currentProject.id]]];
    }

    return params;
  }
}
