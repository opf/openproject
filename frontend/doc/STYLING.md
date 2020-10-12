Styling the frontend
====================

Frontend styling is coupled to the Living Styleguide. The guide implements the same CSS that the application does. It takes the very same Sass files used in the Asset pipeline to build a second css file that is then used for diplaying the guide.

All styles for OpenProject are found in `./app/assets/stylesheets`. The frontend folder contains no styling, besides rendered files and some styling for the styleguide itself.

## Using the styleguide

The styleguide itself is just a long html page demonstrating the components. It can be modified by altering its base file `styleguide.html` (see `./app/assets/styleguide.html`).

The general approach here is that for every partial of sass there is a Markdown file (`*.lsg`) describing it:

```bash
$ cd app/assets/stylesheets/content
$ ls -la _accounts*
_accounts.lsg
_accounts.sass
```

The `lsg` is simple markdown containing information on how to use the component described.

Ideally, this should be only one component per Sass partial, but this is not always possible, as seen in the case of `./app/assets/stylesheets/content/_work_packages.sass` which describes an area of the application instead of a single component.

## A note on the css style used

Originally introduced by `@myabc`, Sass-Code should ideally follow a convention as described in [Simple naming for CSS class names](http://www.hagenburger.net/BLOG/Modular-CSS-Class-Names.html).

So far, mostly Sass partials have been used, grouped by their component. There is still a lot of legacy code in there, especially in the plugins. The legacy code for the core can be found within `./app/assets/stylesheets/_misc_legacy.sass`
