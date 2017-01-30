
import {FilterModelBase} from './filter_model_base';

export class LegacyFilterModel extends FilterModelBase {

  values:any;
  dateValue:String;
  textValue:any;

  constructor(data, legacySchema) {
    super(data.name, data.operator, data.type, legacySchema);
    this.values = data.values;

    // Experimental API controller will always give back strings even for numeric values so need to parse them
    if (this.isSingleInputField() && Array.isArray(this.values)) this.parseSingleValue(this.values[0]);

    this.pruneValues();
  }

  getValuesAsArray() {
    var result = [];
    if (this.isSingleInputField()) {
      if (this.operator == '=d') {
        result.push(this.dateValue);
      }
      else {
        result.push(this.textValue);
      }
    } else if (!Array.isArray(this.values)) {
      if (this.operator == '<>d') {
        if (this.values['0']) {
          result.push(this.values['0']);
        }
        else {
          // make sure that first value does not get pruned
          result.push('undefined');
        }
        if (this.values['1'])
        {
          result.push(this.values['1']);
        }
      }
      else {
        result.push(this.values);
      }
    } else {
      result = this.values;
    }
    return result;
  }

  parseSingleValue(v) {
    if (this.type == 'integer' || this.type == 'date') {
      if (this.operator == '=d') {
        this.dateValue = v;
      }
      else {
        this.textValue = parseInt(v);
      }
    }
    else {
      this.textValue = v;
    }
  }

  pruneValues() {
    if (this.values) {
      if (this.operator == '<>d') {
        this.values = {
          '0': this.values[0] == 'undefined' ? null : this.values[0],
          '1': this.values[1]
        };
      }
      else {
        this.values = this.values.filter(function (value) {
          return value !== '';
        });
      }
    } else {
      this.values = [];
    }
  }

  hasValues() {
    if (this.isSingleInputField()) {
      if (this.operator == '=d') {
        return !!this.dateValue;
      }
      else {
        return !!this.textValue;
      }
    } else if (this.operator == '<>d') {
      return !!(this.values['0'] || this.values['1']);
    } else {
      return Array.isArray(this.values) ? this.values.length > 0 : !!this.values;
    }
  }
}
