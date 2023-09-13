interface IAPIFilter {
  name:string;
  operator:FilterOperator;
  values:ApiV3FilterValueType[];
}

interface IOPAutocompleterOption {
  id:number;
  name:string;
}

type resource = 'work_packages' | 'users' | 'principals';
