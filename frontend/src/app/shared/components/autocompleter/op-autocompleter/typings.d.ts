interface IAPIFilter {
  name:string;
  operator:FilterOperator;
  values:unknown[]|boolean;
};

interface IOPAutocompleterOptions {
  id: number;
  name:string;
};

type resource = 'work_packages' | 'users';