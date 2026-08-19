import { ApiV3FilterValueType, FilterOperator } from 'core-app/shared/helpers/api-v3/api-v3-filter-builder';

export interface IAPIFilter {
  name:string;
  operator:FilterOperator;
  values:ApiV3FilterValueType[];
}

export interface IOPAutocompleterOption {
  id:number;
  name:string;
}

export type TOpAutocompleterResource = 'work_packages' | 'users' | 'principals' | 'projects' | 'portfolios' | 'programs';
