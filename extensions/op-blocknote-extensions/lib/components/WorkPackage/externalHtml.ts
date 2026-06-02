export function buildExternalDOM(
  tag: "div" | "span",
  attrs: Record<string, string>,
  text: string,
  doc: Document,
): HTMLElement {
  const el = doc.createElement(tag);
  for (const [name, value] of Object.entries(attrs)) {
    el.setAttribute(name, value);
  }
  el.textContent = text;
  return el;
}
