import {Injectable, Injector} from "@angular/core";
import {OpModalService} from "core-components/op-modals/op-modal.service";
import {AddGridWidgetModal} from "core-components/grid/widgets/add/add.modal";
import {GridWidgetResource} from "core-app/modules/hal/resources/grid-widget-resource";
import {GridArea} from "core-components/grid/grid.component";

@Injectable()
export class AddGridWidgetService {

  constructor(readonly opModalService:OpModalService,
              readonly injector:Injector) {
  }

  public select(area:GridArea) {
    return new Promise<GridWidgetResource>((resolve, reject) => {
      const modal = this.opModalService.show(AddGridWidgetModal, { });
      modal.closingEvent.subscribe((modal:AddGridWidgetModal) => {
        let registered = modal.chosenWidget;

        let source = {
          _type: 'Widget',
          identifier: registered.identifier,
          startRow: area.startRow,
          endRow: area.endRow,
          startColumn: area.startColumn,
          endColumn: area.endColumn
        };

        let resource = new GridWidgetResource(this.injector,
                                              source,
                                              true,
                                              (resource:any) => { },
                                              'GridWidgetResource' );
        resolve(resource);
      });
    });
  }
}
