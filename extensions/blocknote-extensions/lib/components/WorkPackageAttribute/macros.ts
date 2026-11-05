import type { AttributeDisplay } from './display';

export interface AttributeMacro {
  // A work package id, semantic identifier or subject.
  reference:string;
  attribute:string;
  display:AttributeDisplay;
  source:string;
}

export type MacroSegment = string | AttributeMacro;

// Mirrors OpenProject::TextFormatting::Matchers::AttributeMacros, but only
// for macros that name their work package.
const MACRO = /(?<![\w])workPackage(Label|Value):(?:([^":\s]+)|"([^"]+)"):(?:([^":\s.]+)|"([^"]+)")(?::(?:multiline|singleline)\b)?/g;

// An unquoted layout keyword in the attribute slot marks the relative form
// (`workPackageValue:targetVersions:singleline`), which has no work package.
const LAYOUTS = new Set(['multiline', 'singleline']);

const LABEL_VALUE_SEPARATOR = /^:\s*$/;

export function splitAttributeMacros(text:string):MacroSegment[] {
  const segments:MacroSegment[] = [];
  let last = 0;

  for (const match of text.matchAll(MACRO)) {
    const [source, kind, id, quotedId, attribute, quotedAttribute] = match;
    if (attribute !== undefined && LAYOUTS.has(attribute)) continue;

    pushText(segments, text.slice(last, match.index));
    segments.push({
      reference: id ?? quotedId,
      attribute: attribute ?? quotedAttribute,
      display: kind === 'Label' ? 'label' : 'value',
      source,
    });
    last = match.index + source.length;
  }
  pushText(segments, text.slice(last));

  return mergeLabelValuePairs(segments);
}

function pushText(segments:MacroSegment[], text:string):void {
  if (text) segments.push(text);
}

// `label: value` of the same attribute is how a "both" attribute is copied.
function mergeLabelValuePairs(segments:MacroSegment[]):MacroSegment[] {
  const merged:MacroSegment[] = [];

  for (let index = 0; index < segments.length; index++) {
    const segment = segments[index];
    const separator = segments[index + 1];
    const value = segments[index + 2];

    if (
      typeof segment !== 'string' && segment.display === 'label'
      && typeof separator === 'string' && LABEL_VALUE_SEPARATOR.test(separator)
      && typeof value !== 'string' && value?.display === 'value'
      && value.reference === segment.reference && value.attribute === segment.attribute
    ) {
      merged.push({ ...segment, display: 'both', source: segment.source + separator + value.source });
      index += 2;
    }
    else {
      merged.push(segment);
    }
  }

  return merged;
}
