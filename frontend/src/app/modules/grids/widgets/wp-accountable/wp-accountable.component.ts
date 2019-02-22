import {Component, OnInit} from "@angular/core";
import {ApiV3FilterBuilder} from "core-components/api/api-v3/api-v3-filter-builder";
import {WidgetWpListComponent} from "core-app/modules/grids/widgets/wp-widget/wp-widget.component";

@Component({
  templateUrl: '../wp-widget/wp-widget.component.html',
  styleUrls: ['../wp-widget/wp-widget.component.css']
})

export class WidgetWpAccountableComponent extends WidgetWpListComponent implements OnInit {
  public text = { title: this.i18n.t('js.grid.widgets.work_packages_accountable.title') };
  public queryProps:any;

  ngOnInit() {
    super.ngOnInit();
    let filters = new ApiV3FilterBuilder();
    filters.add('responsible', '=', ["me"]);
    filters.add('status', 'o', []);

    this.queryProps = {"columns[]":["id", "project", "type", "subject"],
      "filters":filters.toJson()};
  }
}

