import {
  ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, Inject, OnInit,
} from '@angular/core';
import { OpModalComponent } from 'core-app/shared/components/modal/modal.component';
import { OpModalLocalsToken } from 'core-app/shared/components/modal/modal.service';
import { OpModalLocalsMap } from 'core-app/shared/components/modal/modal.types';
import { WidgetRegistration } from 'core-app/shared/components/grids/grid/grid.component';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { GridWidgetResource } from 'core-app/features/hal/resources/grid-widget-resource';
import { GridWidgetsService } from 'core-app/shared/components/grids/widgets/widgets.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { BannersService } from 'core-app/core/enterprise/banners.service';
import { LoadingIndicatorService } from 'core-app/core/loading-indicator/loading-indicator.service';
import { enterpriseDocsUrl } from 'core-app/core/setup/globals/constants.const';
import { BehaviorSubject } from 'rxjs';
import { filter, take } from 'rxjs/operators';

@Component({
  templateUrl: './add.modal.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AddGridWidgetModalComponent extends OpModalComponent implements OnInit {
  text = {
    title: this.i18n.t('js.grid.add_widget'),
    close_popup: this.i18n.t('js.button_close'),
    upsale_link: this.i18n.t('js.grid.upsale.link'),
    upsale_text: this.i18n.t('js.grid.upsale.text'),
    cancel_button: this.i18n.t('js.button_cancel'),
    more_info_link: enterpriseDocsUrl.graphWidgets,
  };

  public chosenWidget:WidgetRegistration;

  public eeShowBanners = false;

  private schema:SchemaResource;

  constructor(
    readonly elementRef:ElementRef,
    @Inject(OpModalLocalsToken) readonly locals:OpModalLocalsMap,
    readonly cdRef:ChangeDetectorRef,
    readonly widgetsService:GridWidgetsService,
    readonly i18n:I18nService,
    readonly bannerService:BannersService,
    readonly loadingIndicator:LoadingIndicatorService,
  ) {
    super(locals, cdRef, elementRef);
  }

  ngOnInit() {
    super.ngOnInit();
    this.eeShowBanners = this.bannerService.eeShowBanners;
    this.fetchSchema();
  }

  public get selectable() {
    return this.eligibleWidgets.sort((a, b) => a.title.localeCompare(b.title));
  }

  public select($event:MouseEvent, widget:WidgetRegistration) {
    this.chosenWidget = widget;
    this.closeMe($event);
  }

  public trackWidgetBy(widget:WidgetRegistration) {
    return widget.identifier;
  }

  private fetchSchema():void {
    const $schema = this.locals.$schema as BehaviorSubject<SchemaResource>;
    this.schema = $schema.value;

    if (!this.schema) {
      this.loadingIndicator.modal.start();

      $schema
      .pipe(
        filter<SchemaResource>(Boolean),
        take(1),
      )
      .subscribe((schema:SchemaResource) => {
        this.schema = schema;
        this.loadingIndicator.modal.stop();
        this.cdRef.detectChanges();
      });
    }
  }

  private get eligibleWidgets() {
    if (this.schema) {
      const widgets = this.schema.widgets as { allowedValues:GridWidgetResource[] };
      const schemaWidgetIdentifiers = widgets.allowedValues.map((widget) => widget.identifier);

      return this.widgetsService.registered.filter((widget) => schemaWidgetIdentifiers.includes(widget.identifier));
    }

    return [];
  }
}
