---
sidebar_navigation:
  title:  Timesheet PDF Styling
---

# Timesheet PDF

This document describes the style settings format for the [PDF Export styling file](https://github.com/opf/openproject/blob/dev/modules/reporting/app/workers/cost_query/pdf/standard.yml).

| Key | Description | Data type |
| - | - | - |
| `page` | **Page settings**<br/>Properties to set the basic page settings<br/>See [Page settings](#page-settings) | object |
| `page_logo` | **Page logo**<br/>Styling for logo image in the page header.<br/>See [Page logo](#page-logo) | object |
| `page_header` | **Page headers**<br/>See [Page headers](#page-headers) | object |
| `page_footer` | **Page footers**<br/>See [Page footers](#page-footers) | object |
| `page_heading` | **Page heading**<br/>The main page title heading<br/>See [Page heading](#page-heading) | object |
| `cover` | **Cover page**<br/>Styling for the cover page of the PDF report export<br/>See [Cover page](#cover-page) | object |

## Cover page

Styling for the cover page of the PDF report export

Key: `cover`

Example:

```yml
cover:
  header: {}
  footer: {}
  hero: {}
```

| Key | Description | Data type |
| - | - | - |
| `header` | **Cover page header**<br/>Styling for the cover page header<br/>See [Cover page header](#cover-page-header) | object |
| `footer` | **Cover page footer**<br/>Styling for the cover page footer<br/>See [Cover page footer](#cover-page-footer) | object |
| `hero` | **Cover page hero**<br/>Styling for the hero banner at the bottom at the cover page<br/>See [Cover page hero](#cover-page-hero) | object |

## Cover page footer

Styling for the cover page footer of the PDF report export

Key: `cover_footer`

Example:

```yml
footer:
  offset: 20
  size: 10
  color: 064e80
```

| Key | Description | Data type |
| - | - | - |
| `offset` | **Offset position from page bottom**<br/>A number >= 0 and an optional unit<br/>Example: `30` | number or string<br/>See [Units](#units) |
| … | See [Font properties](#font-properties) |  |

## Cover page header

Styling for the cover page header of the PDF report export

Key: `cover_header`

Example:

```yml
header:
  logo_height: 25
  border: {}
```

| Key | Description | Data type |
| - | - | - |
| `spacing` | **Minimum spacing between logo and page header text**<br/>A number >= 0 and an optional unit<br/>Example: `20` | number or string<br/>See [Units](#units) |
| `offset` | **Offset position from page top**<br/>A number >= 0 and an optional unit<br/>Example: `6.5` | number or string<br/>See [Units](#units) |
| `logo_height` | **Height of the logo in the page header**<br/>A number >= 0 and an optional unit<br/>Example: `25` | number or string<br/>See [Units](#units) |
| `border` | **Cover page header**<br/>Styling for the cover page header<br/>See [Cover page header border](#cover-page-header-border) | object |
| … | See [Font properties](#font-properties) |  |

## Cover page header border

Styling for the cover page header border of the PDF report export

Key: `cover_header_border`

Example:

```yml
border:
  color: d3dee3
  height: 1
  offset: 6
```

| Key | Description | Data type |
| - | - | - |
| `spacing` | **Minimum spacing between logo and page header text**<br/>A number >= 0 and an optional unit<br/>Example: `20` | number or string<br/>See [Units](#units) |
| `offset` | **Offset position from page top**<br/>A number >= 0 and an optional unit<br/>Example: `6` | number or string<br/>See [Units](#units) |
| `height` | **Line height of the border**<br/>A number >= 0 and an optional unit<br/>Example: `25` | number or string<br/>See [Units](#units) |
| `color` | **Line color of the border**<br/>A color in RRGGBB format<br/>Example: `F0F0F0` | string |
| … | See [Font properties](#font-properties) |  |

## Cover page hero

Styling for the hero banner at the bottom at the cover page

Key: `cover_hero`

Example:

```yml
header:
  padding_right: 150
  padding_top: 120
  title: {}
  heading: {}
  subheading: {}
```

| Key | Description | Data type |
| - | - | - |
| `padding_right` | **Padding right**<br/>Padding only on the right side of the hero banner<br/>Examples: `10mm`, `10` | number or string<br/>See [Units](#units) |
| `padding_top` | **Padding top**<br/>Padding only on the top side of the hero banner<br/>Examples: `10mm`, `10` | number or string<br/>See [Units](#units) |
| `title` | **The first block in the hero**<br/>See [The first block in the hero](#the-first-block-in-the-hero) | object |
| `heading` | **The main block in the hero**<br/>See [The main block in the hero](#the-main-block-in-the-hero) | object |
| `dates` | **The dates block in the hero**<br/>See [The dates block in the hero](#the-dates-block-in-the-hero) | object |
| `subheading` | **The last block in the hero**<br/>See [The last block in the hero](#the-last-block-in-the-hero) | object |

## Font properties

Properties to set the font style

Key: `font`

Example:

```yml
font: OpenSans
size: 10
character_spacing: 0
styles: []
color: '000000'
leading: 2
```

| Key | Description | Data type |
| - | - | - |
| `font` |  | string |
| `size` | A number >= 0 and an optional unit<br/>Examples: `10mm`, `10` | number or string<br/>See [Units](#units) |
| `character_spacing` | A number >= 0 and an optional unit<br/>Examples: `10mm`, `10` | number or string<br/>See [Units](#units) |
| `leading` | A number >= 0 and an optional unit<br/>Examples: `10mm`, `10` | number or string<br/>See [Units](#units) |
| `color` | **Color**<br/>A color in RRGGBB format<br/>Example: `F0F0F0` | string |
| `styles` | Example: `[bold]`<br/>Valid values:<br/>`bold`, `italic`, `underline`, `strikethrough`, `superscript`, `subscript` | array of string |

## Margin properties

Properties to set margins

Key: `margin`

Example:

```yml
margin: 10mm
margin_top: 15mm
```

| Key | Description | Data type |
| - | - | - |
| `margin` | **Margin**<br/>One value for margin on all sides<br/>Examples: `10mm`, `10` | number or string<br/>See [Units](#units) |
| `margin_left` | **Margin left**<br/>Margin only on the left side<br/>Examples: `10mm`, `10` | number or string<br/>See [Units](#units) |
| `margin_right` | **Margin right**<br/>Margin only on the right side<br/>Examples: `10mm`, `10` | number or string<br/>See [Units](#units) |
| `margin_top` | **Margin top**<br/>Margin only on the top side<br/>Examples: `10mm`, `10` | number or string<br/>See [Units](#units) |
| `margin_bottom` | **Margin bottom**<br/>Margin only on the bottom side<br/>Examples: `10mm`, `10` | number or string<br/>See [Units](#units) |

## Page footers

Key: `page_footer`

Example:

```yml
page_footer:
  offset: -30
  size: 8
```

| Key | Description | Data type |
| - | - | - |
| `offset` | **Offset position from page bottom**<br/>A positive or negative number and an optional unit<br/>Example: `-30` | number or string<br/>See [Units](#units) |
| `spacing` | **Minimum spacing between different page footers**<br/>A number >= 0 and an optional unit<br/>Example: `8` | number or string<br/>See [Units](#units) |
| … | See [Font properties](#font-properties) |  |

## Page headers

Key: `page_header`

Example:

```yml
page_header:
  align: left
  offset: 20
  size: 8
```

| Key | Description | Data type |
| - | - | - |
| `align` | **Alignment**<br/>How the element should be aligned<br/>Example: `center`<br/>Valid values:<br/>`left`, `center`, `right` | string |
| `offset` | **Offset position from page top**<br/>A positive or negative number and an optional unit<br/>Example: `-30` | number or string<br/>See [Units](#units) |
| … | See [Font properties](#font-properties) |  |

## Page heading

The main page title heading

Key: `page_heading`

Example:

```yml
page_heading:
  size: 14
  styles:
    - bold
  margin_bottom: 10
```

| Key | Description | Data type |
| - | - | - |
| … | See [Font properties](#font-properties) |  |
| … | See [Margin properties](#margin-properties) |  |

## Page logo

Styling for logo image in the page header.

Key: `page_logo`

Example:

```yml
page_logo:
  height: 20
  align: right
```

| Key | Description | Data type |
| - | - | - |
| `height` | **Height of the image**<br/>A number >= 0 and an optional unit<br/>Examples: `10mm`, `10` | number or string<br/>See [Units](#units) |
| `align` | **Alignment**<br/>How the element should be aligned<br/>Example: `center`<br/>Valid values:<br/>`left`, `center`, `right` | string |
| `offset` | **Offset position from page top**<br/>A positive or negative number and an optional unit<br/>Example: `-30` | number or string<br/>See [Units](#units) |

## Page settings

Properties to set the basic page settings

Key: `page`

Example:

```yml
page:
  page_size: EXECUTIVE
  margin_top: 60
  margin_bottom: 60
  margin_left: 36
  margin_right: 36
  page_break_threshold: 200
  link_color: 175A8E
```

| Key | Description | Data type |
| - | - | - |
| `link_color` | **Link color**<br/>Set the color of clickable links<br/>Example: `F0F0F0` | string |
| `page_layout` | **Page layout**<br/>The layout of a page<br/>Example: `portrait`<br/>Valid values:<br/>`portrait`, `landscape` | string |
| `page_size` | **Page size**<br/>The size of a page<br/>Example: `EXECUTIVE`<br/>Valid values:<br/>`EXECUTIVE`, `TABLOID`, `LETTER`, `LEGAL`, `FOLIO`, `A0`, `A1`, `A2`, `A3`, `A4`, `A5`, `A6`, `A7`, `A8`, `A9`, `A10`, `B0`, `B1`, `B2`, `B3`, `B4`, `B5`, `B6`, `B7`, `B8`, `B9`, `B10`, `C0`, `C1`, `C2`, `C3`, `C4`, `C5`, `C6`, `C7`, `C8`, `C9`, `C10`, `RA0`, `RA1`, `RA2`, `RA3`, `RA4`, `SRA0`, `SRA1`, `SRA2`, `SRA3`, `SRA4`, `4A0`, `2A0` | string |
| `page_break_threshold` | **Page break threshold**<br/>If there is a new section, start a new page if space less than the threshold is available<br/>Examples: `10mm`, `10` | number or string<br/>See [Units](#units) |
| … | Default font settings<br/>See [Font properties](#font-properties) |  |
| … | Page margins<br/>See [Margin properties](#margin-properties) |  |

## The dates block in the hero

Key: `dates`

Example:

```yml
heading:
  spacing: 10
  max_height: 20
  size: 32
  color: 414d5f
  styles:
    - bold
```

| Key | Description | Data type |
| - | - | - |
| `max_height` | **Maximum height of the block**<br/>A number >= 0 and an optional unit<br/>Example: `30` | number or string<br/>See [Units](#units) |
| `spacing` | **Minimum spacing between dates and subheading**<br/>A number >= 0 and an optional unit<br/>Example: `10` | number or string<br/>See [Units](#units) |
| … | See [Font properties](#font-properties) |  |

## The first block in the hero

Key: `title`

Example:

```yml
title:
  max_height: 30
  spacing: 10
  font: SpaceMono
  size: 10
  color: 414d5f
```

| Key | Description | Data type |
| - | - | - |
| `spacing` | **Minimum spacing between title and heading**<br/>A number >= 0 and an optional unit<br/>Example: `10` | number or string<br/>See [Units](#units) |
| `max_height` | **Maximum height of the block**<br/>A number >= 0 and an optional unit<br/>Example: `30` | number or string<br/>See [Units](#units) |
| … | See [Font properties](#font-properties) |  |

## The last block in the hero

Key: `subheading`

Example:

```yml
subheading:
  max_height: 30
  size: 10
  color: 414d5f
  styles:
    - italic
```

| Key | Description | Data type |
| - | - | - |
| `max_height` | **Maximum height of the block**<br/>A number >= 0 and an optional unit<br/>Example: `30` | number or string<br/>See [Units](#units) |
| … | See [Font properties](#font-properties) |  |

## The main block in the hero

Key: `heading`

Example:

```yml
heading:
  spacing: 10
  size: 32
  color: 414d5f
  styles:
    - bold
```

| Key | Description | Data type |
| - | - | - |
| `spacing` | **Minimum spacing between heading and subheading**<br/>A number >= 0 and an optional unit<br/>Example: `10` | number or string<br/>See [Units](#units) |
| … | See [Font properties](#font-properties) |  |

## Units

available units are

`mm` - Millimeter, `cm` - Centimeter, `dm` - Decimeter, `m` - Meter

`in` - Inch, `ft` - Feet, `yr` - Yard

`pt` - [Postscript point](https://en.wikipedia.org/wiki/Point_(typography)#Desktop_publishing_point) (default if no unit is used)
