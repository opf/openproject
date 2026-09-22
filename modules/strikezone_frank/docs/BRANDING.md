# Strikezone branding (OpenProject WP #55)

How rebranding is done so it survives OpenProject upgrades. Nothing in this
module forks OpenProject core files; it uses the plugin hooks OpenProject
already documents for themes, views, and settings.

## What the plugin does

1. **Logo** — `hooks/_logo.html.erb` is rendered from `view_layouts_base_html_head`
   (the same hook BIM-style plugins use). It swaps header / login logo images for
   Strikezone SVGs under `app/assets/images/strikezone_frank/`.
2. **Theme colours** — `Patches::ColorThemesPatch` prepends a **Strikezone** entry
   onto `OpenProject::CustomStyles::ColorThemes` (same extension point as BIM).
   Community Edition never applies `DesignColor` CSS, so the hook also sets the
   five Design tokens plus the derived `--*-major1` / `--*-minor*` hover colours
   using OpenProject's `HexColor` helpers. If Enterprise **Administration → Design**
   already has colours saved, the plugin leaves those tokens alone.
3. **Typography** — Baloo Bhaina 2 (weights 400/500/600/700) is self-hosted in
   `app/assets/fonts/strikezone_frank/` and applied via `--body-font-family`.
   Primer title/body size tokens and `.Button` sizes follow the brand type scale.
   Global `h1 { 40px }` is **not** forced, so OpenProject chrome density stays intact.
4. **Application name** — `Branding.apply!` (from the engine `to_prepare`) renames
   stock `Setting.app_title` and `Setting.software_name` from `OpenProject` →
   `Strikezone` only when they are still the defaults. An admin can still change
   the title later in **Administration → Settings → General**.
5. **Theme identity** — `Patches::DesignPatch` overrides
   `OpenProject::CustomStyles::Design` name/identifier (the module is documented
   as plugin-overridable).

## Brand tokens (from Colors.pdf / Brandbook)

| Token | Hex | Source |
|---|---|---|
| `--primary-button-color` | `#DF5301` | Primary 700 |
| `--accent-color` | `#ED6718` | Primary 600 / brand orange |
| `--header-bg-color` | `#101010` | Black |
| `--main-menu-bg-color` | `#FFFFFF` | White |
| `--main-menu-bg-selected-background` | `#FFF3EC` | Primary 50 |
| `--body-font-color` | `#1F1F1F` | Neutral 700 |
| Font | Baloo Bhaina 2 | Brandbook + style guide |

## Prefer admin UI when available

On instances with Enterprise **Administration → Design**, pick the **Strikezone**
theme (or upload logo / favicon / colours there). The plugin CSS still covers
Community Edition and logo selectors Design may not fully replace.

## Deploy notes

- Keep the `openproject-strikezone_frank` gem in `Gemfile.modules`.
- VPN required for `pm.sz24.ai`.
- After deploy, confirm header logo, page titles, login page, primary-button
  hover (orange, not OpenProject green), and Baloo Bhaina 2 on body text; add
  before/after screenshots on WP #55.
