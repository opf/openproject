import {Component, OnInit} from "@angular/core";
import {AbstractWidgetComponent} from "app/modules/grids/widgets/abstract-widget.component";
import {ApiV3FilterBuilder} from "core-components/api/api-v3/api-v3-filter-builder";

@Component({
  templateUrl: '../wp-widget/wp-widget.component.html',
  styleUrls: ['../wp-widget/wp-widget.component.css']
})
export class WidgetWpCreatedComponent extends AbstractWidgetComponent implements OnInit {
  public widgetHeading = 'Work packages created by me';
  public queryProps:any;
  public configuration = { "actionsColumnEnabled": false,
                           "columnMenuEnabled": false,
                           "contextMenuEnabled": false };

  ngOnInit() {
    let filters = new ApiV3FilterBuilder();
    filters.add('author', '=', ["me"]);
    filters.add('status', 'o', []);

    this.queryProps = {"columns[]":["id", "project", "type", "subject"],
      "filters":filters.toJson()};

  }
}
