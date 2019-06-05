import {AbstractWidgetComponent} from "core-app/modules/grids/widgets/abstract-widget.component";
import {Component, OnInit} from '@angular/core';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";
import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {TimezoneService} from "core-components/datetime/timezone.service";
import {NewsResource} from "core-app/modules/hal/resources/news-resource";
import {UserCacheService} from "core-components/user/user-cache.service";
import {UserResource} from "core-app/modules/hal/resources/user-resource";
import {NewsDmService} from "core-app/modules/hal/dm-services/news-dm.service";

@Component({
  templateUrl: './news.component.html',
})
export class WidgetNewsComponent extends AbstractWidgetComponent implements OnInit {
  public text = {
    title: this.i18n.t('js.grid.widgets.news.title'),
    createdBy: this.i18n.t('js.label_created_by'),
    at: this.i18n.t('js.grid.widgets.news.at'),
    noResults: this.i18n.t('js.grid.widgets.news.no_results'),
  };

  public entries:NewsResource[] = [];
  private entriesLoaded = false;

  constructor(readonly halResource:HalResourceService,
              readonly pathHelper:PathHelperService,
              readonly i18n:I18nService,
              readonly timezone:TimezoneService,
              readonly userCache:UserCacheService,
              readonly newsDm:NewsDmService) {
    super(i18n);
  }

  ngOnInit() {
    this.newsDm
      .list({ sortBy: [['created_on', 'desc']], pageSize: 3 })
      .then((collection) => {
        this.entries = collection.elements as NewsResource[];
        this.entriesLoaded = true;

        this.entries.forEach((entry) => {
          if (!entry.author) {
            return;
          }

          this.userCache
            .require(entry.author.idFromLink)
            .then((user:UserResource) => {
              entry.author = user;
            });
        });
      });
  }

  public newsPath(news:NewsResource) {
    return `${this.pathHelper.appBasePath}/news/${news.id}`;
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

  public newsAuthorAvatar(news:NewsResource) {
    return news.author.avatar;
  }

  public newsCreated(news:NewsResource) {
    return this.timezone.formattedDatetime(news.createdAt);
  }

  public get noEntries() {
    return !this.entries.length && this.entriesLoaded;
  }
}
