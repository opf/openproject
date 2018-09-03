export namespace Highlighting {
  export function rowClass(property:string, id:string|number) {
    return `__hl_row_${property}_${id}`;
  }

  export function inlineClass(property:string, id:string|number) {
    return `__hl_inl_${property}_${id}`;
  }

  export function isBright(styles:CSSStyleDeclaration, property:string, id:string|number) {
    const variable = `--hl-${property}-${id}-dark`;
    return styles.getPropertyValue(variable) !== '';
  }
}
