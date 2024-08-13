import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, OnInit, } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  ExternalQueryConfigurationService
} from 'core-app/features/work-packages/components/wp-table/external-configuration/external-query-configuration.service';
import { UrlParamsHelperService } from 'core-app/features/work-packages/components/wp-query/url-params-helper';


@Component({
  selector: 'opce-editable-query-props',
  templateUrl: './editable-query-props.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class EditableQueryPropsComponent implements OnInit {
  id:string|null;

  name:string|null;

  urlParams = false;

  queryProps:string;

  text = {
    edit_query: this.I18n.t('js.admin.type_form.edit_query'),
  };

  constructor(private elementRef:ElementRef,
    private I18n:I18nService,
    private cdRef:ChangeDetectorRef,
    private urlParamsHelper:UrlParamsHelperService,
    private externalQuery:ExternalQueryConfigurationService) {
  }

  ngOnInit() {
    const element = this.elementRef.nativeElement;
    this.id = element.dataset.id;
    this.name = element.dataset.name;
    this.urlParams = element.dataset.urlParams === 'true';

    this.queryProps = element.dataset.query;
  }

  public editQuery() {
    const queryProperties = (() => {
      if (this.urlParams) {
        return this.queryProps;
      }

      try {
        return JSON.parse(this.queryProps);
      } catch (e) {
        console.error(`Failed to parse query props from ${this.queryProps}: ${e}`);
        return {};
      }
    })();

    this.externalQuery.show({
      currentQuery: queryProperties,
      urlParams: this.urlParams,
      callback: (queryProps:any) => {
        this.queryProps = this.urlParams ? queryProps : JSON.stringify(queryProps);
        this.cdRef.detectChanges();
      },
    });
  }
}
