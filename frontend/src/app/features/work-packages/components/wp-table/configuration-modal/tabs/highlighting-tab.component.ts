import {
  ChangeDetectionStrategy,
  Component,
  Injector,
  ViewChild,
} from '@angular/core';
import { TabComponent } from 'core-app/features/work-packages/components/wp-table/configuration-modal/tab-portal-outlet';
import { WorkPackageViewHighlightingService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-highlighting.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { HighlightingMode } from 'core-app/features/work-packages/components/wp-fast-table/builders/highlighting/highlighting-mode.const';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { BannersService } from 'core-app/core/enterprise/banners.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { NgSelectComponent } from '@ng-select/ng-select';
import { States } from 'core-app/core/states/states.service';
import { enterpriseDocsUrl } from 'core-app/core/setup/globals/constants.const';
import { repositionDropdownBugfix } from 'core-app/shared/components/autocompleter/op-autocompleter/autocompleter.helper';

@Component({
  templateUrl: './highlighting-tab.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WpTableConfigurationHighlightingTabComponent implements TabComponent {
  // Display mode
  public highlightingMode:HighlightingMode = 'inline';

  public entireRowMode = false;

  public lastEntireRowAttribute:HighlightingMode = 'status';

  public eeShowBanners = false;

  public availableInlineHighlightedAttributes:HalResource[] = [];

  public selectedAttributes:any[] = [];

  public availableRowHighlightedAttributes:{ name:string; value:HighlightingMode }[] = [];

  @ViewChild('highlightedAttributesNgSelect') public highlightedAttributesNgSelect:NgSelectComponent;

  @ViewChild('rowHighlightNgSelect') public rowHighlightNgSelect:NgSelectComponent;

  public text = {
    title: this.I18n.t('js.work_packages.table_configuration.highlighting'),
    highlighting_mode: {
      description: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.description'),
      none: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.none'),
      inline: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.inline'),
      inline_all_attributes: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.inline_all'),
      status: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.status'),
      type: this.I18n.t('js.work_packages.properties.type'),
      priority: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.priority'),
      entire_row_by: this.I18n.t('js.work_packages.table_configuration.highlighting_mode.entire_row_by'),
    },
    upsaleAttributeHighlighting: this.I18n.t('js.work_packages.table_configuration.upsale.attribute_highlighting'),
    upsaleCheckOutLink: this.I18n.t('js.work_packages.table_configuration.upsale.check_out_link'),
    more_info_link: enterpriseDocsUrl.tableHighlighting,
  };

  constructor(readonly injector:Injector,
    readonly I18n:I18nService,
    readonly states:States,
    readonly querySpace:IsolatedQuerySpace,
    readonly Banners:BannersService,
    readonly wpTableHighlight:WorkPackageViewHighlightingService) {
  }

  ngOnInit() {
    this.availableInlineHighlightedAttributes = this.availableHighlightedAttributes;
    this.availableRowHighlightedAttributes = [
      { name: this.text.highlighting_mode.status, value: 'status' },
      { name: this.text.highlighting_mode.priority, value: 'priority' },
    ];

    this.setSelectedValues();

    this.eeShowBanners = this.Banners.eeShowBanners;
    this.updateMode(this.wpTableHighlight.current.mode);

    if (this.eeShowBanners) {
      this.updateMode('none');
    }
  }

  public onSave() {
    const mode = this.highlightingMode;
    this.wpTableHighlight.update({ mode, selectedAttributes: this.selectedAttributes });
  }

  public updateMode(mode:HighlightingMode | 'entire-row') {
    if (mode === 'entire-row') {
      this.highlightingMode = this.lastEntireRowAttribute;
    } else {
      this.highlightingMode = mode;
    }

    if (['status', 'priority'].indexOf(this.highlightingMode) !== -1) {
      this.lastEntireRowAttribute = this.highlightingMode;
      this.entireRowMode = true;
    } else {
      this.entireRowMode = false;
    }
  }

  public updateHighlightingAttributes(model:HalResource[]) {
    this.selectedAttributes = model;
  }

  public disabledValue(value:boolean):string | null {
    return value ? 'disabled' : null;
  }

  public get availableHighlightedAttributes():HalResource[] {
    const { schema } = this.querySpace.queryForm.value!;
    return schema.highlightedAttributes.allowedValues;
  }

  public onOpen(component:unknown) {
    repositionDropdownBugfix(component);
  }

  private setSelectedValues() {
    const currentValues = this.wpTableHighlight.current.selectedAttributes;

    if (currentValues) {
      this.selectedAttributes = currentValues;
    }
  }
}
