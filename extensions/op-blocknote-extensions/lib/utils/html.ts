export function escapeHtmlText(value:string):string {
  return value.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

export function escapeHtmlAttribute(value:string):string {
  return escapeHtmlText(value).replace(/"/g, '&quot;');
}
