import type { AttributeDisplay } from './display';

export interface AttributeMacro {
  // A work package id, semantic identifier or subject.
  reference:string;
  attribute:string;
  display:AttributeDisplay;
  start:number;
  end:number;
}

// Mirrors OpenProject::TextFormatting::Matchers::AttributeMacros, but only
// for macros that name their work package.
const MACRO = /(?<![\w])workPackage(Label|Value):(?:([^":\s]+)|"([^"]+)"):(?:([^":\s.]+)|"([^"]+)")(?::(?:multiline|singleline)\b)?/g;

// An unquoted layout keyword in the attribute slot marks the relative form
// (`workPackageValue:targetVersions:singleline`), which has no work package.
const LAYOUTS = new Set(['multiline', 'singleline']);

const LABEL_VALUE_SEPARATOR = /^:\s*$/;

export function findAttributeMacros(text:string):AttributeMacro[] {
  const macros:AttributeMacro[] = [];

  for (const match of text.matchAll(MACRO)) {
    const [source, kind, id, quotedId, attribute, quotedAttribute] = match;
    if (attribute !== undefined && LAYOUTS.has(attribute)) continue;

    macros.push({
      reference: id ?? quotedId,
      attribute: attribute ?? quotedAttribute,
      display: kind === 'Label' ? 'label' : 'value',
      start: match.index,
      end: match.index + source.length,
    });
  }

  return mergeLabelValuePairs(text, macros);
}

// `label: value` of the same attribute is how a "both" attribute is copied.
function mergeLabelValuePairs(text:string, macros:AttributeMacro[]):AttributeMacro[] {
  const merged:AttributeMacro[] = [];

  for (let index = 0; index < macros.length; index++) {
    const label = macros[index];
    const value = macros[index + 1] as AttributeMacro | undefined;

    if (
      label.display === 'label' && value?.display === 'value'
      && value.reference === label.reference && value.attribute === label.attribute
      && LABEL_VALUE_SEPARATOR.test(text.slice(label.end, value.start))
    ) {
      merged.push({ ...label, display: 'both', end: value.end });
      index += 1;
    }
    else {
      merged.push(label);
    }
  }

  return merged;
}
