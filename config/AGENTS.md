# Config

## Translations
- UI strings must use translation keys (never hard-coded)
- Source translations in `**/config/locales/en.yml` can be modified directly
- Other translations managed via Crowdin

```bash
bundle exec i18n-tasks missing                        # Show missing translation keys
bundle exec i18n-tasks unused                         # Show unused translation keys
bundle exec i18n-tasks normalize                      # Fix/normalize translation files
bundle exec i18n-tasks check-consistent-interpolations  # Check interpolation consistency
```
