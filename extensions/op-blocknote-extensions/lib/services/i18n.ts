import i18n from "i18next";
import { initReactI18next } from "react-i18next";
import { en } from "../locales/en.ts";

export function initLanguage(locale: string) {
  i18n.changeLanguage(locale);
}

const resources: Record<string, any> = {
  en,
};

const localeModules = import.meta.glob("../locales/crowdin/*.ts", { eager: true });

for (const path in localeModules) {
  const locale = path.match(/([^/]+)\.ts$/)?.[1];
  if (locale) {
    const mod = localeModules[path] as any;
    resources[locale] = mod[locale] || mod.default || Object.values(mod)[0];
  }
}

if (!i18n.isInitialized) {
  i18n
    .use(initReactI18next)
    .init({
      resources,
      lng: "en",
      fallbackLng: "en",
      interpolation: {
        escapeValue: false // React already safes from xss
      }
    });
}

export default i18n;