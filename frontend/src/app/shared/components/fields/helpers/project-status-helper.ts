import { I18nService } from 'core-app/core/i18n/i18n.service';

export function projectStatusCodeCssClass(code:string|null|undefined):string {
  code = ensureDefaultCode(code);

  return `-${code.replace('_', '-')}`;
}

export function projectStatusI18n(code:string|null|undefined, I18n:I18nService):string {
  code = ensureDefaultCode(code);

  return I18n.t(`js.grid.widgets.project_status.${code.replace('-', '_')}`);
}

function ensureDefaultCode(code:string|null|undefined):string {
  return code || 'not-set';
}
