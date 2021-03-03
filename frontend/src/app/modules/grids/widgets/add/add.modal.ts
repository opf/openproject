import { Component, ElementRef, Inject, ChangeDetectorRef } from "@angular/core";
import { OpModalComponent } from "core-app/modules/modal/modal.component";
import { OpModalLocalsToken } from "core-app/modules/modal/modal.service";
import { OpModalLocalsMap } from "core-app/modules/modal/modal.types";
import { WidgetRegistration } from "app/modules/grids/grid/grid.component";
import { GridWidgetsService } from "app/modules/grids/widgets/widgets.service";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { BannersService } from "core-app/modules/common/enterprise/banners.service";

@Component({
  templateUrl: './add.modal.html'
})
export class AddGridWidgetModal extends OpModalComponent {

  text = {
    title: this.i18n.t('js.grid.add_widget'),
    close_popup: this.i18n.t('js.button_close'),
    upsale_link: this.i18n.t('js.grid.upsale.link'),
    upsale_text: this.i18n.t('js.grid.upsale.text')
  };

  public chosenWidget:WidgetRegistration;
  public eeShowBanners = false;

  constructor(readonly elementRef:ElementRef,
              @Inject(OpModalLocalsToken) readonly locals:OpModalLocalsMap,
              readonly cdRef:ChangeDetectorRef,
              readonly widgetsService:GridWidgetsService,
              readonly i18n:I18nService,
              readonly bannerService:BannersService) {
    super(locals, cdRef, elementRef);
  }

  ngOnInit() {
    super.ngOnInit();
    this.eeShowBanners = this.bannerService.eeShowBanners;
  }

  public get selectable() {
    return this.eligibleWidgets.sort((a, b) => {
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

  private get eligibleWidgets() {
    const schemaWidgetIdentifiers = this.locals.schema.widgets.allowedValues.map((widget:any) => {
      return widget.identifier;
    });

    return this.widgetsService.registered.filter((widget) => {
      return schemaWidgetIdentifiers.includes(widget.identifier);
    });
  }
}
