import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, OnInit } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  ExternalQueryConfigurationService,
} from 'core-app/features/work-packages/components/wp-table/external-configuration/external-query-configuration.service';

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

  constructor(
    private elementRef:ElementRef<HTMLElement>,
    private I18n:I18nService,
    private cdRef:ChangeDetectorRef,
    private externalQuery:ExternalQueryConfigurationService,
  ) {
  }

  ngOnInit() {
    const element = this.elementRef.nativeElement;
    this.id = element.dataset.id as string;
    this.name = element.dataset.name as string;
    this.urlParams = element.dataset.urlParams === 'true';

    this.queryProps = element.dataset.query as string;
  }

  public editQuery() {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
    const queryProperties = (() => {
      if (this.urlParams) {
        return this.queryProps;
      }

      try {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-return
        return JSON.parse(this.queryProps);
      } catch (e) {
        console.error(`Failed to parse query props from ${this.queryProps}: ${e}`);
        return {};
      }
    })();

    this.externalQuery.show({
      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
      currentQuery: queryProperties,
      urlParams: this.urlParams,
      callback: (queryProps:string) => {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
        this.queryProps = this.urlParams ? queryProps : JSON.stringify(queryProps);
        this.cdRef.detectChanges();
      },
    });
  }
}
