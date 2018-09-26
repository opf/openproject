import {Component, Injector} from '@angular/core';
import {TabComponent} from 'core-components/wp-table/configuration-modal/tab-portal-outlet';
import {WorkPackageTableHighlightingService} from 'core-components/wp-fast-table/state/wp-table-highlighting.service';
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {HighlightingMode} from "core-components/wp-fast-table/builders/highlighting/highlighting-mode.const";
import {MultiToggledSelectOption} from "core-app/modules/common/multi-toggled-select/multi-toggled-select.component";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {States} from "core-app/components/states.service";
import {WorkPackageTableHighlight} from "core-components/wp-fast-table/wp-table-highlight";

@Component({
  templateUrl: './highlighting-tab.component.html'
})
export class WpTableConfigurationHighlightingTab implements TabComponent {

  // Display mode
  public highlightingMode:HighlightingMode = 'inline';
  public entireRowMode:boolean = false;
  public lastEntireRowAttribute:HighlightingMode = 'status';
  public eeShowBanners:boolean = false;

  public availableMappedHighlightedAttributes:MultiToggledSelectOption[] = [];
  public selectedAttributes:undefined|MultiToggledSelectOption|MultiToggledSelectOption[] = [];

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
    upsaleEnterpriseOnly: this.I18n.t('js.work_packages.table_configuration.upsale.ee_only'),
    upsaleAttributeHighlighting: this.I18n.t('js.work_packages.table_configuration.upsale.attribute_highlighting'),
    upsaleCheckOutLink: this.I18n.t('js.work_packages.table_configuration.upsale.check_out_link')
  };

  constructor(readonly injector:Injector,
              readonly I18n:I18nService,
              readonly states:States,
              readonly wpTableHighlight:WorkPackageTableHighlightingService) {
  }

  public onSave() {
    let mode = this.highlightingMode;
    let selectedAttributes:HalResource[]|undefined = undefined;

    if (this.selectedAttributes !== undefined && _.get(this.selectedAttributes, 'value') !== 'all') {
      selectedAttributes = _.castArray(this.selectedAttributes)
        .map(el => _.find(this.availableHighlightedAttributes, (column) => column.href === el.value)!);
    }

    const newValue = new WorkPackageTableHighlight(mode, selectedAttributes);
    this.wpTableHighlight.update(newValue);

  }

  public updateMode(mode:HighlightingMode|'entire-row') {
    if (mode === 'entire-row') {
      this.highlightingMode = this.lastEntireRowAttribute;
    } else {
      this.highlightingMode = mode;
    }

    if (['status', 'priority', 'type'].indexOf(this.highlightingMode) !== -1) {
      this.lastEntireRowAttribute = this.highlightingMode;
      this.entireRowMode = true;
    } else {
      this.entireRowMode = false;
    }
  }

  public disabledValue(value:boolean):string|null {
    return value ? 'disabled' : null;
  }

  ngOnInit() {
    this.availableMappedHighlightedAttributes =
      [this.allAttributesOption].concat(this.getAvailableAttributes());

    // Either, selectedAttributes already exist, then map them to multi value options
    const currentValues = this.wpTableHighlight.current.selectedAttributes;
    if (currentValues === undefined) {
      this.selectedAttributes = this.allAttributesOption;
    } else if (currentValues.length === 1) {
      this.selectedAttributes = this.mapAttributes(currentValues)[0];
    } else {
      this.selectedAttributes = this.mapAttributes(currentValues);
    }

    this.eeShowBanners = jQuery('body').hasClass('ee-banners-visible');
    this.updateMode(this.wpTableHighlight.current.mode);

    if (this.eeShowBanners) {
      this.updateMode('none');
    }
  }

  public get availableHighlightedAttributes():HalResource[] {
    const schema = this.states.query.form.value!.schema;
    return schema.highlightedAttributes.allowedValues;
  }

  public getAvailableAttributes():MultiToggledSelectOption[] {
    return this.mapAttributes(this.availableHighlightedAttributes);
  }

  private mapAttributes(input:HalResource[]):MultiToggledSelectOption[] {
    return input.map((el:HalResource) => ({ name: el.name, value: el.$href! }));
  }

  private get allAttributesOption():MultiToggledSelectOption {
    return { name: this.text.highlighting_mode.inline_all_attributes, singleOnly: true, value: 'all' };
  }
}
