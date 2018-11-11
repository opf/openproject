import {Component} from "@angular/core";
import {AbstractWidgetComponent} from "core-components/grid/widgets/abstract-widget.component";

@Component({
  templateUrl: './wp-watched.component.html',
})
export class WidgetWpWatchedComponent extends AbstractWidgetComponent {
  public queryProps = {"columns[]":["id","project","type","subject"],"filters":"[{\"watcher\":{\"operator\":\"=\",\"values\":[\"me\"]}},{\"status\":{\"operator\":\"o\",\"values\":[]}}]"};
  public configuration = { "actionsColumnEnabled":false,
                           "columnMenuEnabled":false,
                           "contextMenuEnabled":false };
}
