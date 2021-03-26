interface IAPIFilter {
  name:string;
  operator:FilterOperator;
  values:unknown[]|boolean;
};

type res = 'work_packages' | 'users';