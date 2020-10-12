import {Injectable} from "@angular/core";
import {WidgetRegistration} from "app/modules/grids/grid/grid.component";
import {HookService} from "app/modules/plugins/hook-service";

@Injectable()
export class GridWidgetsService {
  constructor(private Hook:HookService) {}

  public get registered() {
    let registeredWidgets:WidgetRegistration[] = [];

    _.each(this.Hook.call('gridWidgets'), (registration:WidgetRegistration[]) => {
      registeredWidgets = registeredWidgets.concat(registration);
    });

    return registeredWidgets;
  }
}
