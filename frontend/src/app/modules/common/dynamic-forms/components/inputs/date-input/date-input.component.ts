import { Component, OnInit } from '@angular/core';
import { FieldType } from "@ngx-formly/core";
import * as moment from "moment";
import { TimezoneService } from "core-components/datetime/timezone.service";

@Component({
  selector: 'app-date-input',
  templateUrl: './date-input.component.html',
  styleUrls: ['./date-input.component.scss'],
})
export class DateInputComponent  extends FieldType implements OnInit {

  constructor(
    private _timezoneService:TimezoneService
  ) {
    super();
  }

  ngOnInit(): void {
    console.log('ngOnInit', this.formControl)
  }

  public parser(data:any) {
    if (moment(data, 'YYYY-MM-DD', true).isValid()) {
      return data;
    } else {
      return null;
    }
  }

  public formatter(data:any) {
    if (moment(data, 'YYYY-MM-DD', true).isValid()) {
      var d = this._timezoneService.parseDate(data);
      return this._timezoneService.formattedISODate(d);
    } else {
      return null;
    }
  }
}
