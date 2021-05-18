interface IAPIFilter {
  name:string;
  operator:FilterOperator;
  values:unknown[]|boolean;
};

type resource = 'work_packages' | 'users';