# OpenProject icon font

**All icons and resulting fonts This directory is licensed under the Creative Commons Attribution 3.0 Unported License**.

Copyright (C) 2013 the OpenProject Foundation (OPF)
This work is based on the following sources
Minicons Free Vector Icons Pack http://www.webalys.com/minicons and
User Interface Design framework http://www.webalys.com/design-interface-application-framework.php

Creative Commons Attribution 3.0 Unported License
This license can also be found at this permalink: http://creativecommons.org/licenses/by/3.0/

## Structure

This directory is the source for the generated icon font in the Rails `app/assets/font` directory.
Since it seldomly changes, it is only rebuilt manually and on demand.

## Rebuilding

To rebuild the font (e.g., after changing icons in the source `svg` directory), use the node script `generate.js`.

```
$ cd app/assets/fonts/openproject_icon
$ node generate.js
```

To use, you need to install the webfonts generator package with: `npm install webfonts-generator`.
