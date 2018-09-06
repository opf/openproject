export namespace Highlighting {
  export function rowClass(property:string, id:string|number) {
    return `__hl_row_${property}_${id}`;
  }

  export function inlineClass(property:string, id:string|number) {
    return `__hl_inl_${property}_${id}`;
  }

  export function dotClass(property:string, id:string|number) {
    return `__hl_dot_${property}_${id}`;
  }

  /**
   * Given the difference from today (negative = n days in the past),
   * output the fixed overdue classes
   * @param diff
   */
  export function overdueDate(diff:number):string {
    if (diff === 0) {
      return '__hl_date_due_today';
    }
    // At least one day
    if (diff <= -1) {
      return '__hl_date_overdue';
    }

    return '__hl_date_not_overdue';
  }

  export function isBright(styles:CSSStyleDeclaration, property:string, id:string|number) {
    const variable = `--hl-${property}-${id}-dark`;
    return styles.getPropertyValue(variable) !== '';
  }
}
