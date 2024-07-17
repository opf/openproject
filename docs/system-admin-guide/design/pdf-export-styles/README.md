
# PDF Export Styling yml

This document describes the style settings format for the [PDF Export styling file](https://github.com/opf/openproject/blob/dev/app/models/work_package/pdf_export/standard.yml)

| Key | Description | Data type |
| - | - | - |
| `page` | **Page settings**<br/>Properties to set the basic page settings<br/>See [Page settings](#page-settings) | object |
| `page_logo` | **Page logo**<br/>Styling for logo image in the page header.<br/>See [Page logo](#page-logo) | object |
| `page_header` | **Page headers**<br/>See [Page headers](#page-headers) | object |
| `page_footer` | **Page footers**<br/>See [Page footers](#page-footers) | object |
| `page_heading` | **Page heading**<br/>The main page title heading<br/>See [Page heading](#page-heading) | object |
| `work_package` | **Work package**<br/>Styling for the Work package section<br/>See [Work package](#work-package) | object |
| `toc` | **Table of content**<br/>Styling for the table of content of the PDF report export<br/>See [Table of content](#table-of-content) | object |
| `cover` | **Cover page**<br/>Styling for the cover page of the PDF report export<br/>See [Cover page](#cover-page) | object |
| `overview` | **Overview**<br/>Styling for the PDF table export<br/>See [Overview](#overview) | object |

## Alert

Styling to denote a quote as alert box

Key: `alert`

Example:

```yaml
ALERT:
  alert_color: f4f9ff
  border_color: f4f9ff
  border_width: 2
  no_border_right: true
  no_border_left: false
  no_border_bottom: true
  no_border_top: true
```

| Key | Description | Data type |
| - | - | - |
| `background_color` | **Color**<br/>A color in RRGGBB format<br/>Example: `F0F0F0` | string |
| `alert_color` | **Color**<br/>A color in RRGGBB format<br/>Example: `F0F0F0` | string |
| … | See [Font properties](#font-properties) |  |
| … | See [Border Properties](#border-properties) |  |
| … | See [Padding Properties](#padding-properties) |  |
| … | See [Margin properties](#margin-properties) |  |

## Border Properties

Properties to set borders

Key: `border`

Example:

```yaml
border_color: F000FF
border_color_top: 000FFF
border_color_bottom: FFF000
no_border_left: true
no_border_right: true
border_width: 0.25mm
border_width_left: 0.5mm
border_width_right: 0.5mm
```

| Key | Description | Data type |
| - | - | - |
| `border_width` | **Border width**<br/>One value for border line width on all sides<br/>Examples: `10mm`, `10` | number or string<br/>See [Units](#units) |
| `border_width_left` | **Border width left**<br/>Border width only on the left side<br/>Examples: `10mm`, `10` | number or string<br/>See [Units](#units) |
| `border_width_top` | **Border width top**<br/>Border width only on the top side<br/>Examples: `10mm`, `10` | number or string<br/>See [Units](#units) |
| `border_width_right` | **Border width right**<br/>Border width only on the right side<br/>Examples: `10mm`, `10` | number or string<br/>See [Units](#units) |
| `border_width_bottom` | **Border width bottom**<br/>Border width only on the bottom side<br/>Examples: `10mm`, `10` | number or string<br/>See [Units](#units) |
| `border_color` | **Border color**<br/>One value for border color on all sides<br/>Example: `F0F0F0` | string |
| `border_color_left` | **Border color left**<br/>Border color only on the left side<br/>Example: `F0F0F0` | string |
| `border_color_top` | **Border color top**<br/>Border color only on the top side<br/>Example: `F0F0F0` | string |
| `border_color_right` | **Border color right**<br/>Border color only on the right side<br/>Example: `F0F0F0` | string |
| `border_color_bottom` | **Border color bottom**<br/>Border color only on the bottom side<br/>Example: `F0F0F0` | string |
| `no_border` | **Disable borders**<br/>Turn off borders on all sides | boolean |
| `no_border_left` | **Disable border left**<br/>Turn off border on the left sides | boolean |
| `no_border_top` | **Disable border top**<br/>Turn off border on the top sides | boolean |
| `no_border_right` | **Disable border right**<br/>Turn off border on the right sides | boolean |
| `no_border_bottom` | **Disable border bottom**<br/>Turn off border on the bottom sides | boolean |

## Cover page

Styling for the cover page of the PDF report export

Key: `cover`

Example:

```yaml
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

```yaml
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

```yaml
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

```yaml
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

```yaml
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
| `subheading` | **The last block in the hero**<br/>See [The last block in the hero](#the-last-block-in-the-hero) | object |

## Font properties

Properties to set the font style

Key: `font`

Example:

```yaml
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

## Image caption

Styling for the caption below an image

Key: `caption`

| Key | Description | Data type |
| - | - | - |
| `align` | Valid values:<br/>`left`, `center`, `right`, `justify` | string |
| … | See [Font properties](#font-properties) |  |
| … | See [Padding Properties](#padding-properties) |  |

## Margin properties

Properties to set margins

Key: `margin`

Example:

```yaml
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

## Markdown Link

Styling a clickable link

Key: `link`

Example:

```yaml
link:
  color: '000088'
```

| Key | Description | Data type |
| - | - | - |
| … | See [Font properties](#font-properties) |  |

## Markdown Styling

Styling for content of work package description and long text custom fields

Key: `markdown`

Example:

```yaml
markdown:
  font: {}
  header: {}
  header_1: {}
  header_2: {}
  header_3: {}
  paragraph: {}
  unordered_list: {}
  unordered_list_point: {}
  ordered_list: {}
  ordered_list_point: {}
  task_list: {}
  task_list_point: {}
  link: {}
  code: {}
  blockquote: {}
  codeblock: {}
  table: {}
```

| Key | Description | Data type |
| - | - | - |
| `font` | **Font properties**<br/>Properties to set the font style<br/>See [Font properties](#font-properties) | object |
| `paragraph` | **Markdown paragraph**<br/>A block of text<br/>See [Markdown paragraph](#markdown-paragraph) | object |
| `table` | **Markdown table**<br/>See [Markdown table](#markdown-table) | object |
| `headless_table` | **Markdown headless table**<br/>Tables without or empty header rows can be styled differently.<br/>See [Markdown headless table](#markdown-headless-table) | object |
| `code` | **Markdown code**<br/>Styling to denote a word or phrase as code<br/>See [Markdown code](#markdown-code) | object |
| `codeblock` | **Markdown code block**<br/>Styling to denote a paragraph as code<br/>See [Markdown code block](#markdown-code-block) | object |
| `link` | **Markdown Link**<br/>Styling a clickable link<br/>See [Markdown Link](#markdown-link) | object |
| `image` | **Markdown image**<br/>Styling of images<br/>See [Markdown image](#markdown-image) | object |
| `hrule` | **Markdown horizontal rule**<br/>Styling for horizontal lines<br/>See [Markdown horizontal rule](#markdown-horizontal-rule) | object |
| `header` | **Markdown header**<br/>Default styling for headers on all levels.<br/>use header_`x` as key for header level `x`.<br/>See [Markdown header](#markdown-header) | object |
| `blockquote` | **Markdown blockquote**<br/>Styling to denote a paragraph as quote<br/>See [Markdown blockquote](#markdown-blockquote) | object |
| `ordered_list` | **Markdown ordered list**<br/>Default styling for ordered lists on all levels.<br/>use ordered_list_`x` as key for ordered list level `x`.<br/>See [Markdown ordered list](#markdown-ordered-list) | object |
| `ordered_list_point` | **Markdown ordered list point**<br/>Default styling for ordered list points on all levels.<br/>use ordered_list_point_`x` as key for ordered list points level `x`.<br/>See [Markdown ordered list point](#markdown-ordered-list-point) | object |
| `unordered_list` | **Markdown unordered list**<br/>Default styling for unordered lists on all levels.<br/>use unordered_list_`x` as key for unordered list level `x`.<br/>See [Markdown unordered list](#markdown-unordered-list) | object |
| `unordered_list_point` | **Markdown unordered list point**<br/>Default styling for unordered list points on all levels.<br/>use unordered_list_point_`x` as key for unordered list points level `x`.<br/>See [Markdown unordered list point](#markdown-unordered-list-point) | object |
| `task_list` | **Markdown task list**<br/>See [Markdown unordered list](#markdown-unordered-list) | object |
| `task_list_point` | **Markdown task list point**<br/>See [Markdown task list point](#markdown-task-list-point) | object |
| `alerts` | **alert boxes (styled blockquotes)**<br/>See [alert boxes (styled blockquotes)](#alert-boxes-styled-blockquotes) | object |
| `ordered_list_point_1`<br/>`ordered_list_point_2`<br/>`ordered_list_point_x` | Markdown ordered list point level<br/>See [Markdown ordered list point](#markdown-ordered-list-point) | object |
| `ordered_list_1`<br/>`ordered_list_2`<br/>`ordered_list_x` | Markdown ordered list level<br/>See [Markdown ordered list](#markdown-ordered-list) | object |
| `unordered_list_point_1`<br/>`unordered_list_point_2`<br/>`unordered_list_point_x` | Markdown unordered list point level<br/>See [Markdown unordered list point](#markdown-unordered-list-point) | object |
| `unordered_list_1`<br/>`unordered_list_2`<br/>`unordered_list_x` | Markdown unordered List Level<br/>See [Markdown unordered list](#markdown-unordered-list) | object |
| `header_1`<br/>`header_2`<br/>`header_x` | Markdown header level<br/>See [Markdown header](#markdown-header) | object |

## Markdown blockquote

Styling to denote a paragraph as quote

Key: `blockquote`

Example:

```yaml
blockquote:
  background_color: f4f9ff
  size: 14
  styles:
    - italic
  color: 0f3b66
  border_color: b8d6f4
  border_width: 1
  no_border_right: true
  no_border_left: false
  no_border_bottom: true
  no_border_top: true
```

| Key | Description | Data type |
| - | - | - |
| `background_color` | **Color**<br/>A color in RRGGBB format<br/>Example: `F0F0F0` | string |
| … | See [Font properties](#font-properties) |  |
| … | See [Border Properties](#border-properties) |  |
| … | See [Padding Properties](#padding-properties) |  |
| … | See [Margin properties](#margin-properties) |  |

## Markdown code

Styling to denote a word or phrase as code

Key: `code`

Example:

```yaml
code:
  font: Consolas
  color: '880000'
```

| Key | Description | Data type |
| - | - | - |
| … | See [Font properties](#font-properties) |  |

## Markdown code block

Styling to denote a paragraph as code

Key: `codeblock`

Example:

```yaml
codeblock:
  background_color: F5F5F5
  font: Consolas
  size: 8
  color: '880000'
  padding: 3mm
  margin_top: 2mm
  margin_bottom: 2mm
```

| Key | Description | Data type |
| - | - | - |
| `background_color` | **Color**<br/>A color in RRGGBB format<br/>Example: `F0F0F0` | string |
| … | See [Font properties](#font-properties) |  |
| … | See [Padding Properties](#padding-properties) |  |
| … | See [Margin properties](#margin-properties) |  |

## Markdown header

Key: `header`

Example:

```yaml
header:
  styles:
    - bold
  padding_top: 2mm
  padding_bottom: 2mm
header_1:
  size: 14
  styles:
    - bold
    - italic
header_2:
  size: 12
  styles:
    - bold
```

| Key | Description | Data type |
| - | - | - |
| … | See [Font properties](#font-properties) |  |
| … | See [Padding Properties](#padding-properties) |  |

## Markdown headless table

Tables without or empty header rows can be styled differently.

Key: `headless_table`

Example:

```yaml
headless_table:
  auto_width: true
  cell:
    style: underline
    background_color: 000FFF
```

| Key | Description | Data type |
| - | - | - |
| `auto_width` | **Automatic column widths**<br/>Table columns should fit the content, equal spacing of columns if value is `false` | boolean |
| `cell` | **Table cell**<br/>Styling for a table cell<br/>See [Table cell](#table-cell) | object |
| … | See [Margin properties](#margin-properties) |  |
| … | See [Border Properties](#border-properties) |  |

## Markdown horizontal rule

Styling for horizontal lines

Key: `hrule`

Example:

```yaml
hrule:
  line_width: 1
```

| Key | Description | Data type |
| - | - | - |
| `line_width` | **Sets the stroke width of the horizontal rule**<br/>A number >= 0 and an optional unit<br/>Examples: `10mm`, `10` | number or string<br/>See [Units](#units) |
| … | See [Margin properties](#margin-properties) |  |

## Markdown image

Styling of images

Key: `image`

Example:

```yaml
image:
  max_width: 50mm
  margin: 2mm
  margin_bottom: 3mm
  align: center
  caption:
    align: center
    size: 8
```

| Key | Description | Data type |
| - | - | - |
| `max_width` | **Maximum width of the image**<br/>A number >= 0 and an optional unit<br/>Examples: `10mm`, `10` | number or string<br/>See [Units](#units) |
| `align` | **Alignment**<br/>How the element should be aligned<br/>Example: `center`<br/>Valid values:<br/>`left`, `center`, `right` | string |
| `caption` | **Image caption**<br/>Styling for the caption below an image<br/>See [Image caption](#image-caption) | object |
| … | See [Margin properties](#margin-properties) |  |

## Markdown ordered list

Key: `ordered_list`

Example:

```yaml
ordered_list:
  spacing: 2mm
  point_inline: false
```

| Key | Description | Data type |
| - | - | - |
| `spacing` | **Spacing**<br/>Additional space between list items<br/>Examples: `10mm`, `10` | number or string<br/>See [Units](#units) |
| `point_inline` | **Inline Point**<br/>Do not indent paragraph text, but include the point into the first paragraph | boolean |
| … | See [Font properties](#font-properties) |  |
| … | See [Padding Properties](#padding-properties) |  |

## Markdown ordered list point

Key: `ordered_list_point`

Example:

```yaml
ordered_list_point:
  template: "<number>."
  alphabetical: false
  spacing: 0.75mm
  spanning: true
```

| Key | Description | Data type |
| - | - | - |
| `spacing` | A number >= 0 and an optional unit<br/>Examples: `10mm`, `10` | number or string<br/>See [Units](#units) |
| `alphabetical` | **Alphabetical bullet points**<br/>Convert the list item number into a character, eg. `a.` `b.` `c.` | boolean |
| `spanning` | **Spanning**<br/>Use the width of the largest bullet as indention. | boolean |
| `template` | **Template**<br/>customize what the prefix should contain, eg. `(<number>)` | string |
| … | See [Font properties](#font-properties) |  |

## Markdown paragraph

A block of text

Key: `paragraph`

Example:

```yaml
paragraph:
  align: justify
  padding_bottom: 2mm
```

| Key | Description | Data type |
| - | - | - |
| `align` | Valid values:<br/>`left`, `center`, `right`, `justify` | string |
| … | See [Font properties](#font-properties) |  |
| … | See [Padding Properties](#padding-properties) |  |

## Markdown table

Key: `table`

Example:

```yaml
table:
  auto_width: true
  header:
    background_color: F0F0F0
    no_repeating: true
    size: 12
  cell:
    background_color: 000FFF
    size: 10
```

| Key | Description | Data type |
| - | - | - |
| `auto_width` | **Automatic column widths**<br/>Table columns should fit the content, equal spacing of columns if value is `false` | boolean |
| `header` | **Table header cell**<br/>Styling for a table header cell<br/>See [Table header cell](#table-header-cell) | object |
| `cell` | **Table cell**<br/>Styling for a table cell<br/>See [Table cell](#table-cell) | object |
| … | See [Margin properties](#margin-properties) |  |
| … | See [Border Properties](#border-properties) |  |

## Markdown task list point

Key: `task_list_point`

Example:

```yaml
task_list_point:
  checked: "☑"
  unchecked: "☐"
  spacing: 0.75mm
```

| Key | Description | Data type |
| - | - | - |
| `checked` | **Checked sign**<br/>Sign for checked state of a task list item | string |
| `unchecked` | **Unchecked sign**<br/>Sign for unchecked state of a task list item | string |
| `spacing` | **Spacing**<br/>Additional space between point and list item content<br/>Examples: `10mm`, `10` | number or string<br/>See [Units](#units) |
| … | See [Font properties](#font-properties) |  |

## Markdown unordered list

Key: `unordered_list`

Example:

```yaml
unordered_list:
  spacing: 1.5mm
  padding_top: 2mm
  padding_bottom: 2mm
```

| Key | Description | Data type |
| - | - | - |
| `spacing` | **Spacing**<br/>Additional space between list items<br/>Examples: `10mm`, `10` | number or string<br/>See [Units](#units) |
| … | See [Font properties](#font-properties) |  |
| … | See [Padding Properties](#padding-properties) |  |

## Markdown unordered list point

Key: `unordered_list_point`

Example:

```yaml
unordered_list_point:
  sign: "•"
  spacing: 0.75mm
```

| Key | Description | Data type |
| - | - | - |
| `sign` | **Sign**<br/>The 'bullet point' character used in the list | string |
| `spacing` | **Spacing**<br/>Space between point and list item content<br/>Examples: `10mm`, `10` | number or string<br/>See [Units](#units) |
| … | See [Font properties](#font-properties) |  |

## Overview

Styling for the PDF table export

Key: `overview`

Example:

```yaml
overview:
  group_heading: {}
  table: {}
```

| Key | Description                                                                                                                                   | Data type |
| - |-----------------------------------------------------------------------------------------------------------------------------------------------| - |
| `group_heading` | **Overview group heading**<br/>Styling for the group level if grouping is activated<br/>See [Overview group heading](#overview-group-heading) | object |
| `table` | **Overview table**<br/>See [Overview table](#overview-table)                                                                                  | object |

## Overview group heading

Styling for the group level if grouping is activated

Key: `group_heading`

Example:

```yaml
group_heading:
  size: 11
  styles:
    - bold
  margin_bottom: 10
```

| Key | Description | Data type |
| - | - | - |
| … | See [Font properties](#font-properties) |  |
| … | See [Margin properties](#margin-properties) |  |

## Overview table

Key: `table`

Example:

```yaml
table:
  subject_indent: 0
  margin_bottom: 20
  cell:
    size: 9
    color: '000000'
    padding: 5
  cell_header:
    size: 9
    styles:
    - bold
  cell_sums:
    size: 8
    styles:
    - bold
```

| Key | Description | Data type |
| - | - | - |
| `subject_indent` | **Indent subject**<br/>Indent by work package level in the subject cell<br/>Examples: `10mm`, `10` | number or string<br/>See [Units](#units) |
| `cell` | **Table cell**<br/>Styling for a table value cell<br/>See [Table cell](#table-cell) | object |
| `cell_header` | **Table header cell**<br/>Styling for a table header cell<br/>See [Table cell](#table-cell) | object |
| `cell_sums` | **Table sum cell**<br/>Styling for a table sum cell<br/>See [Table cell](#table-cell) | object |
| … | See [Margin properties](#margin-properties) |  |

## Padding Properties

Properties to set paddings

Key: `padding`

Example:

```yaml
padding: 10mm
padding_top: 15mm
```

| Key | Description | Data type |
| - | - | - |
| `padding` | **Padding**<br/>One value for padding on all sides<br/>Examples: `10mm`, `10` | number or string<br/>See [Units](#units) |
| `padding_left` | **Padding left**<br/>Padding only on the left side<br/>Examples: `10mm`, `10` | number or string<br/>See [Units](#units) |
| `padding_right` | **Padding right**<br/>Padding only on the right side<br/>Examples: `10mm`, `10` | number or string<br/>See [Units](#units) |
| `padding_top` | **Padding top**<br/>Padding only on the top side<br/>Examples: `10mm`, `10` | number or string<br/>See [Units](#units) |
| `padding_bottom` | **Padding bottom**<br/>Padding only on the bottom side<br/>Examples: `10mm`, `10` | number or string<br/>See [Units](#units) |

## Page footers

Key: `page_footer`

Example:

```yaml
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

```yaml
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

```yaml
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

```yaml
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

```yaml
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

## Table cell

Styling for a table cell

Key: `table_cell`

Example:

```yaml
table_cell:
  size: 9
  color: '000000'
  padding: 5
  border_width: 1
```

| Key | Description | Data type |
| - | - | - |
| … | See [Font properties](#font-properties) |  |
| … | See [Padding Properties](#padding-properties) |  |
| … | See [Border Properties](#border-properties) |  |

## Table header cell

Styling for a table header cell

Key: `table_header`

Example:

```yaml
table_header:
  size: 9
  styles:
    - bold
```

| Key | Description | Data type |
| - | - | - |
| `background_color` | **Color**<br/>A color in RRGGBB format<br/>Example: `F0F0F0` | string |
| `no_repeating` |  | boolean |
| … | See [Font properties](#font-properties) |  |

## Table of content

Styling for the table of content of the PDF report export

Key: `toc`

Example:

```yaml
toc:
  subject_indent: 4
  indent_mode: stairs
  margin_top: 10
  margin_bottom: 20
  item:
    size: 9
    color: '000000'
    margin_bottom: 4
  item_level_1:
    size: 10
    styles:
    - bold
    margin_top: 4
    margin_bottom: 4
  item_level_2:
    size: 10
```

| Key | Description | Data type |
| - | - | - |
| `subject_indent` | **Indention width**<br/>Indention width for TOC levels<br/>Examples: `10mm`, `10` | number or string<br/>See [Units](#units) |
| `indent_mode` | **Indention mode**<br/>`flat`= no indention, `stairs` = indent on each level, `third_level` = indent only at 3th level<br/>Valid values:<br/>`flat`, `stairs`, `third_level` | string |
| `item` | **Table of content item**<br/>Default styling for TOC items on all levels.<br/>use item_level_x` as key for TOC items on level `x`.<br/>See [Table of content item](#table-of-content-item) | object |
| … | See [Margin properties](#margin-properties) |  |
| `item_level_1`<br/>`item_level_2`<br/>`item_level_x` | See [Table of content item level](#table-of-content-item-level) | object |

## Table of content item

Default styling for TOC items on all levels.<br/>use item_level_x` as key for TOC items on level `x`.

Key: `item`

Example:

```yaml
item:
  size: 9
  color: '000000'
  margin_bottom: 4
```

| Key | Description | Data type |
| - | - | - |
| … | See [Font properties](#font-properties) |  |
| … | See [Margin properties](#margin-properties) |  |

## Table of content item level

Key: `item_level_x`

| Key | Description | Data type |
| - | - | - |
| … | See [Font properties](#font-properties) |  |
| … | See [Margin properties](#margin-properties) |  |

## The first block in the hero

Key: `title`

Example:

```yaml
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

```yaml
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

```yaml
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

## Work package

Styling for the Work package section

Key: `work_package`

Example:

```yaml
work_package:
  margin_bottom: 20
  subject: {}
  subject_level_1: {}
  subject_level_2: {}
  subject_level_3: {}
  attributes_table: {}
  markdown_label: {}
  markdown_margin: {}
  markdown: {}
```

| Key | Description | Data type |
| - | - | - |
| `subject` | **Work package subject**<br/>Styling for the Work package subject headline<br/>See [Work package subject](#work-package-subject) | object |
| `attributes_table` | **Work package attributes**<br/>Styling for the Work package attributes table<br/>See [Work package attributes](#work-package-attributes) | object |
| `markdown_label` | **Work package markdown label**<br/>Label headline for work package description and long text custom fields<br/>See [Work package markdown label](#work-package-markdown-label) | object |
| `markdown_margin` | **Work package markdown margins**<br/>Margins for work package description and long text custom fields<br/>See [Work package markdown margins](#work-package-markdown-margins) | object |
| `markdown` | **Markdown Styling**<br/>Styling for content of work package description and long text custom fields<br/>See [Markdown Styling](#markdown-styling) | object |
| … | See [Margin properties](#margin-properties) |  |
| `subject_level_1`<br/>`subject_level_2`<br/>`subject_level_x` | See [Work package subject level](#work-package-subject-level) | object |

## Work package attributes

Styling for the Work package attributes table

Key: `attributes_table`

Example:

```yaml
attributes_table:
  margin_bottom: 10
  cell:
    size: 9
    color: '000000'
    padding_left: 5
    padding_right: 5
    padding_top: 0
    padding_bottom: 5
    border_color: 4B4B4B
    border_width: 0.25
  cell_label:
    styles:
    - bold
```

| Key | Description | Data type |
| - | - | - |
| `cell` | **Attribute value table cell**<br/>Styling for a table cell with attribute value<br/>See [Table cell](#table-cell) | object |
| `cell_label` | **Attribute label table cell**<br/>Styling for a table cell with attribute label<br/>See [Table cell](#table-cell) | object |
| … | See [Margin properties](#margin-properties) |  |

## Work package markdown label

Label headline for work package description and long text custom fields

Key: `markdown_label`

Example:

```yaml
markdown_label:
  size: 12
  styles:
    - bold
  margin_top: 2
  margin_bottom: 4
```

| Key | Description | Data type |
| - | - | - |
| … | See [Font properties](#font-properties) |  |
| … | See [Margin properties](#margin-properties) |  |

## Work package markdown margins

Margins for work package description and long text custom fields

Key: `markdown_margin`

Example:

```yaml
markdown_margin:
  margin_bottom: 16
```

| Key | Description | Data type |
| - | - | - |
| … | See [Margin properties](#margin-properties) |  |

## Work package subject

Styling for the Work package subject headline

Key: `subject`

Example:

```yaml
subject:
  size: 10
  styles:
    - bold
  margin_bottom: 10
```

| Key | Description | Data type |
| - | - | - |
| … | See [Font properties](#font-properties) |  |
| … | See [Margin properties](#margin-properties) |  |

## Work package subject level

Key: `subject_level_x`

Example:

```yaml
subject_level_1:
  size: 14
  styles:
    - bold
subject_level_2:
  size: 13
  styles:
    - bold
subject_level_3:
  size: 12
  styles:
    - bold
```

| Key | Description | Data type |
| - | - | - |
| … | See [Font properties](#font-properties) |  |
| … | See [Margin properties](#margin-properties) |  |

## alert boxes (styled blockquotes)

Key: `alerts`

| Key | Description | Data type |
| - | - | - |
| `NOTE` | **Alert**<br/>Styling to denote a quote as alert box<br/>See [Alert](#alert) | object |
| `TIP` | **Alert**<br/>Styling to denote a quote as alert box<br/>See [Alert](#alert) | object |
| `WARNING` | **Alert**<br/>Styling to denote a quote as alert box<br/>See [Alert](#alert) | object |
| `IMPORTANT` | **Alert**<br/>Styling to denote a quote as alert box<br/>See [Alert](#alert) | object |
| `CAUTION` | **Alert**<br/>Styling to denote a quote as alert box<br/>See [Alert](#alert) | object |

## Units

available units are

`mm` - Millimeter, `cm` - Centimeter, `dm` - Decimeter, `m` - Meter

`in` - Inch, `ft` - Feet, `yr` - Yard

`pt` - [Postscript point](https://en.wikipedia.org/wiki/Point_(typography)#Desktop_publishing_point) (default if no unit is used)
