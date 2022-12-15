# OpenProject icon font

**All icons and resulting fonts This directory is licensed under the Creative Commons Attribution 3.0 Unported License**.

Copyright (C) 2013 the OpenProject Foundation (OPF)
This work is based on the following sources
Minicons Free Vector Icons Pack http://www.webalys.com/minicons and
User Interface Design framework http://www.webalys.com/design-interface-application-framework.php

Creative Commons Attribution 3.0 Unported License
This license can also be found at this permalink: http://creativecommons.org/licenses/by/3.0/

## Structure

This directory is the source for the generated icon font in the Rails
`frontend/src/global_styles/fonts` directory.

Since it seldomly changes, it is only rebuilt manually and on demand.

## Rebuilding

To rebuild the font (e.g., after changing icons in the source `src/` directory
under this README), use the npm task `icon-font:generate`.

```
$ cd frontend
$ npm run icon-font:generate
```
