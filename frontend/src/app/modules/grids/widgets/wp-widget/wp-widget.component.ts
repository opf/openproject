import {AbstractWidgetComponent} from "app/modules/grids/widgets/abstract-widget.component";
import {OnInit} from "@angular/core";
import {
  WorkPackageTableConfiguration,
  WorkPackageTableConfigurationObject
} from "core-components/wp-table/wp-table-configuration";

export class WidgetWpListComponent extends AbstractWidgetComponent implements OnInit {
  // An heuristic based on paddings, margins, the widget header height and the pagination height
  private static widgetSpaceOutsideTable:number = 230;
  private static wpLineHeight:number = 40;
  private static gridAreaHeight:number = 100;
  private static gridAreaSpace:number = 20;

  public configuration:Partial<WorkPackageTableConfiguration> = {
    actionsColumnEnabled: false,
    columnMenuEnabled: false,
    hierarchyToggleEnabled: false,
    contextMenuEnabled: false
  };

  ngOnInit() {
    this.configuration.forcePerPageOption = this.calculatePerPageOption();
  }

  private calculatePerPageOption():number|false {
    if (this.resource) {
      let numberOfRows = this.resource.height;
      let availableHeight = numberOfRows * WidgetWpListComponent.gridAreaHeight +
        (numberOfRows - 1) * WidgetWpListComponent.gridAreaSpace;
      let perPageOption:number = Math.floor((availableHeight - WidgetWpListComponent.widgetSpaceOutsideTable) / WidgetWpListComponent.wpLineHeight);

      return perPageOption < 1 ? 1 : perPageOption;
    } else {
      return false;
    }
  }
}
