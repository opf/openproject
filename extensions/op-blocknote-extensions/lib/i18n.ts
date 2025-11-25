import i18n from "i18next";
import { initReactI18next } from "react-i18next";
import { en } from "./locales/en/OpenProjectWorkPackageTranslations";

if (!i18n.isInitialized) {
  i18n
    .use(initReactI18next) // Passes i18n down to react-i18next
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