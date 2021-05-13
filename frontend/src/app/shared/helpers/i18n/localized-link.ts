export namespace I18nHelpers {

  export interface LocalizedLinkMap {
    [key:string]:string;

    en:string;
  }

  /**
   * Return the matching link for the current locale
   *
   * @param map A hash of locale => URL to use
   */
  export function localizeLink(map:LocalizedLinkMap) {
    const locale = I18n.locale;

    return map[locale] || map.en;
  }
}
