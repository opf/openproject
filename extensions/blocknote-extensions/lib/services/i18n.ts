import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import { en } from '../locales/en.ts';

export function initLanguage(locale:string) {
  void i18n.changeLanguage(locale);
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const resources:Record<string, any> = {
  en,
};

const localeModules = import.meta.glob('../locales/crowdin/*.ts', { eager: true });

for (const path in localeModules) {
  const locale = (/([^/]+)\.ts$/.exec(path))?.[1];
  if (locale) {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any, @typescript-eslint/no-unsafe-assignment
    const mod = localeModules[path] as any;
    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access, @typescript-eslint/prefer-nullish-coalescing, @typescript-eslint/no-unsafe-argument
    resources[locale] = mod[locale] || mod.default || Object.values(mod)[0];
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
