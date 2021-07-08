interface IAPIFilter {
  name:string;
  operator:FilterOperator;
  values:ApiV3FilterValueType[];
}

interface IOPAutocompleterOptions {
  id:number;
  name:string;
}

type resource = 'work_packages' | 'users';
