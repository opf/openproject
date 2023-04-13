export const I18nServiceStub = {
  t<T=string>(name:string):any {
    return {
      'date.abbr_day_names': [],
      'date.day_names': [],
      'date.abbr_month_names': [
        'Jan', 
        'Feb', 
        'Mar', 
        'Apr', 
        'May', 
        'Jun', 
        'Jul', 
        'Aug', 
        'Sep', 
        'Oct', 
        'Nov', 
        'Dec',
      ],
      'date.month_names': [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ],
    }[name] || name as T;
  },
};
