import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, OnInit } from "@angular/core";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { ExternalQueryConfigurationService } from "core-components/wp-table/external-configuration/external-query-configuration.service";
import { UrlParamsHelperService } from "core-components/wp-query/url-params-helper";

export const editableQueryPropsSelector = 'editable-query-props';

@Component({
  selector: editableQueryPropsSelector,
  templateUrl: './editable-query-props.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class EditableQueryPropsComponent implements OnInit {
  id:string|null;
  name:string|null;
  urlParams = false;

  queryProps:string;

  text = {
    edit_query: this.I18n.t('js.admin.type_form.edit_query')
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
    let queryProps:any = this.queryProps;

    if (!this.urlParams) {
      try {
        queryProps = JSON.parse(this.queryProps);
      } catch (e) {
        console.error(`Failed to parse query props from ${this.queryProps}: ${e}`);
        queryProps = {};
      }
    }

    this.externalQuery.show({
      currentQuery: queryProps,
      urlParams: this.urlParams,
      callback: (queryProps:any) => {
        this.queryProps = this.urlParams ? queryProps : JSON.stringify(queryProps);
        this.cdRef.detectChanges();
      }
    });
  }
}