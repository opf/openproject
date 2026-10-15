/** Text read as a work package subject, which holds a single line. */
export function subjectOf(text:string):string {
  return text.replace(/\s+/g, ' ').trim();
}
