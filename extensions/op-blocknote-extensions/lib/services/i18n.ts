import i18n, { type Resource, type ResourceLanguage } from 'i18next';
import { initReactI18next } from 'react-i18next';

export function initLanguage(locale:string) {
  void i18n.changeLanguage(locale);
}

const localeFiles = import.meta.glob<Record<string, ResourceLanguage>>(
  ['../locales/en.yml', '../locales/crowdin/*.yml'],
  { eager: true, import: 'default' },
);

const resources:Resource = {};

for (const [path, content] of Object.entries(localeFiles)) {
  const locale = (/([^/]+)\.yml$/.exec(path))?.[1];
  const translations = Object.values(content)[0];
  if (locale && translations) {
    resources[locale] = translations;
  }
}

if (!i18n.isInitialized) {
  void i18n
    .use(initReactI18next)
    .init({
      resources,
      lng: 'en',
      fallbackLng: 'en',
    });
}

export default i18n;
