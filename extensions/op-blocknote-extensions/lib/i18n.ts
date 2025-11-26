import i18n from "i18next";
import { initReactI18next } from "react-i18next";
import { en } from "./locales/en";

export function initLanguage(locale: string) {
  i18n.changeLanguage(locale);
}

if (!i18n.isInitialized) {
  i18n
    .use(initReactI18next)
    .init({
      resources: {
        en
      },
      lng: "en",
      fallbackLng: "en",
      interpolation: {
        escapeValue: false // React already safes from xss
      }
    });
}

export default i18n;