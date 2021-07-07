import {
  ChangeDetectorRef, Component, ElementRef, Inject,
} from '@angular/core';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import { WidgetRegistration } from 'core-app/shared/components/grids/grid/grid.component';
import { GridWidgetsService } from 'core-app/shared/components/grids/widgets/widgets.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { BannersService } from 'core-app/core/enterprise/banners.service';

@Component({
  templateUrl: './add.modal.html',
})
export class AddGridWidgetModalComponent extends OpModalComponent {
  text = {
    title: this.i18n.t('js.grid.add_widget'),
    close_popup: this.i18n.t('js.button_close'),
    upsale_link: this.i18n.t('js.grid.upsale.link'),
    upsale_text: this.i18n.t('js.grid.upsale.text'),
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
    return this.eligibleWidgets.sort((a, b) => a.title.localeCompare(b.title));
  }

  public select($event:any, widget:WidgetRegistration) {
    this.chosenWidget = widget;
    this.closeMe($event);
  }

  public trackWidgetBy(widget:WidgetRegistration) {
    return widget.identifier;
  }

  private get eligibleWidgets() {
    const schemaWidgetIdentifiers = this.locals.schema.widgets.allowedValues.map((widget:any) => widget.identifier);

    return this.widgetsService.registered.filter((widget) => schemaWidgetIdentifiers.includes(widget.identifier));
  }
}
