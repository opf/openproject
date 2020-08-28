import {ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, OnInit} from "@angular/core";
import {I18nService} from "core-app/modules/common/i18n/i18n.service";
import {ExternalQueryConfigurationService} from "core-components/wp-table/external-configuration/external-query-configuration.service";

export const editableQueryPropsSelector = 'editable-query-props';

@Component({
  selector: editableQueryPropsSelector,
  templateUrl: './editable-query-props.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class EditableQueryPropsComponent implements OnInit {
  id:string|null;
  name:string|null;

  queryProps:string;

  text = {
    edit_query: this.I18n.t('js.admin.type_form.edit_query')
  };

  constructor(private elementRef:ElementRef,
              private I18n:I18nService,
              private cdRef:ChangeDetectorRef,
              private externalQuery:ExternalQueryConfigurationService) {
  }

  ngOnInit() {
    const element = this.elementRef.nativeElement;
    this.id = element.dataset.id;
    this.name = element.dataset.name;

    this.queryProps = element.dataset.query;
  }

  public editQuery() {
    let json;

    try {
      json = JSON.parse(this.queryProps);
    } catch (e) {
      console.error(`Failed to parse query props from ${this.queryProps}: ${e}`);
      json = {};
    }

    this.externalQuery.show(
      json,
      (queryProps:any) => {
        this.queryProps = JSON.stringify(queryProps);
        this.cdRef.detectChanges();
      }
    );
  }
}