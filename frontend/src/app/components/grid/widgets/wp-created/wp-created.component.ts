import {Component} from "@angular/core";
import {AbstractWidgetComponent} from "core-components/grid/widgets/abstract-widget.component";

@Component({
  templateUrl: '../wp-widget/wp-widget.component.html',
  styleUrls: ['../wp-widget/wp-widget.component.css']
})
export class WidgetWpCreatedComponent extends AbstractWidgetComponent{
  public widgetHeading = 'Work packages created by me';
  public queryProps = { "columns[]": ["id", "project", "type", "subject"] ,
                        "filters": "[{\"author\":{\"operator\":\"=\",\"values\":[\"me\"]}},{\"status\":{\"operator\":\"o\",\"values\":[]}}]"};
  public configuration = { "actionsColumnEnabled":false,
                           "columnMenuEnabled":false,
                           "contextMenuEnabled":false };
}
