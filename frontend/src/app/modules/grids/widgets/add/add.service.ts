import {Injectable, Injector} from "@angular/core";
import {OpModalService} from "app/components/op-modals/op-modal.service";
import {AddGridWidgetModal} from "app/modules/grids/widgets/add/add.modal";
import {GridWidgetResource} from "app/modules/hal/resources/grid-widget-resource";
import {GridArea} from "app/modules/grids/areas/grid-area";
import {HalResourceService} from "core-app/modules/hal/services/hal-resource.service";

@Injectable()
export class AddGridWidgetService {

  constructor(readonly opModalService:OpModalService,
              readonly injector:Injector,
              readonly halResource:HalResourceService) {
  }

  public select(area:GridArea) {
    return new Promise<GridWidgetResource>((resolve, reject) => {
      const modal = this.opModalService.show(AddGridWidgetModal, { });
      modal.closingEvent.subscribe((modal:AddGridWidgetModal) => {
        let registered = modal.chosenWidget;

        let source = {
          _type: 'GridWidget',
          identifier: registered.identifier,
          startRow: area.startRow,
          endRow: area.endRow,
          startColumn: area.startColumn,
          endColumn: area.endColumn
        };

        let resource = this.halResource.createHalResource(source) as GridWidgetResource;

        resolve(resource);
      });
    });
  }
}
