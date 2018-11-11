import {Component} from "@angular/core";
import {AbstractWidgetComponent} from "core-components/grid/widgets/abstract-widget.component";

@Component({
  templateUrl: './wp-created.component.html',
})
export class WidgetWpCreatedComponent extends AbstractWidgetComponent{
  public queryProps = { "columns[]": ["id", "project", "type", "subject"] ,
                        "filters": "[{\"author\":{\"operator\":\"=\",\"values\":[\"me\"]}},{\"status\":{\"operator\":\"o\",\"values\":[]}}]"};
  public configuration = { "actionsColumnEnabled":false,
                           "columnMenuEnabled":false,
                           "contextMenuEnabled":false };
}
