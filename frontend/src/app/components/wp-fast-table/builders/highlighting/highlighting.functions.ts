export namespace Highlighting {
  export function backgroundClass(property:string, id:string|number) {
    return `__hl_background_${property}_${id}`;
  }

  export function inlineClass(property:string, id:string|number) {
    return `__hl_inline_${property}_${id}`;
  }

  export function colorClass(highlightColorTextInline:boolean, id:string|number) {
    if (highlightColorTextInline) {
      return `__hl_inline_color_${id}_text`;
    } else {
      return `__hl_inline_color_${id}_dot`;
    }
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
