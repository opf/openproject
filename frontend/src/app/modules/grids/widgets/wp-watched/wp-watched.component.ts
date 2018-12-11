import {Component, OnInit} from "@angular/core";
import {AbstractWidgetComponent} from "app/modules/grids/widgets/abstract-widget.component";
import {ApiV3FilterBuilder} from "core-components/api/api-v3/api-v3-filter-builder";

@Component({
  templateUrl: '../wp-widget/wp-widget.component.html',
  styleUrls: ['../wp-widget/wp-widget.component.css']
})
export class WidgetWpWatchedComponent extends AbstractWidgetComponent implements OnInit {
  public text = { title: this.i18n.t('js.grid.widgets.work_packages_watched.title') };
  public queryProps:any;
  public configuration = { "actionsColumnEnabled": false,
                           "columnMenuEnabled": false,
                           "contextMenuEnabled": false };

  ngOnInit() {
    let filters = new ApiV3FilterBuilder();
    filters.add('watcher', '=', ["me"]);
    filters.add('status', 'o', []);

    this.queryProps = {"columns[]":["id", "project", "type", "subject"],
                       "filters":filters.toJson()};

  }
}
