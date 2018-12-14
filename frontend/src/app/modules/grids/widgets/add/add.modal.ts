import {Component, ElementRef, Inject, ChangeDetectorRef} from "@angular/core";
import {OpModalComponent} from "app/components/op-modals/op-modal.component";
import {WidgetRegistration} from "app/modules/grids/grid/grid.component";
import {OpModalLocalsToken} from "app/components/op-modals/op-modal.service";
import {OpModalLocalsMap} from "app/components/op-modals/op-modal.types";
import {GridWidgetsService} from "app/modules/grids/widgets/widgets.service";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";

@Component({
  templateUrl: './add.modal.html'
})
export class AddGridWidgetModal extends OpModalComponent {

  text = { title: this.i18n.t('js.grid.add_modal.choose_widget'),
           close_popup: this.i18n.t('js.button_close') };

  public chosenWidget:WidgetRegistration;

  constructor(readonly elementRef:ElementRef,
              @Inject(OpModalLocalsToken) readonly locals:OpModalLocalsMap,
              readonly cdRef:ChangeDetectorRef,
              readonly widgetsService:GridWidgetsService,
              readonly i18n:I18nService) {

    super(locals, cdRef, elementRef);
  }

  public get selectable() {
    return this.widgetsService.registered.map((widget) => {
      return {
        identifier: widget.identifier,
        title: this.i18n.t(`js.grid.widgets.${widget.identifier}.title`),
        component: widget.component
      };
    }).sort((a, b) => {
      return a.title.localeCompare(b.title);
    });
  }

  public select($event:any, widget:WidgetRegistration) {
    this.chosenWidget = widget;
    this.closeMe($event);
  }

  public trackWidgetBy(widget:WidgetRegistration) {
    return widget.identifier;
  }
}
