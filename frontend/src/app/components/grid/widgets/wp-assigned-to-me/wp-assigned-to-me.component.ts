import {Component} from "@angular/core";

@Component({
  templateUrl: './wp-assigned-to-me.component.html',

  //TODO: remove selector as the widgets will be generated in code
  selector: 'widget-wp-assigned-to-me'
})

export class WidgetWpAssignedToMeComponent {
  public queryProps = '{"columns[]":["id","project","type","subject"],"filters":"[{\"assignee\":{\"operator\":\"=\",\"values\":[\"me\"]}},{\"status\":{\"operator\":\"o\",\"values\":[]}}]"}';
  public configuration = {"actionsColumnEnabled":false,"columnMenuEnabled":false,"contextMenuEnabled":false};
}

