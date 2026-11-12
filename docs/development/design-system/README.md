---
sidebar_navigation:
  title: Primer Design system
  priority: 998
description: OpenProject adapt Design System
keywords: Design system, Primer, styles, design, components
---
# Design System and Component Libraries

OpenProject uses the [Primer Design System](https://primer.style/product/). New UI is built with Primer ViewComponents rendered by Rails. Relevant reusable components from Primer as well as common patterns and compositions of these components are documented in our [Lookbook](https://qa.openproject-edge.com/lookbook/).

## Where to find things

- OpenProject-specific components built on top of Primer live in [`app/components/op_primer/`](https://github.com/opf/openproject/tree/dev/app/components/op_primer).
- Forms are built with Primer forms: form classes inherit from [`ApplicationForm`](https://github.com/opf/openproject/blob/dev/app/forms/application_form.rb), a subclass of `Primer::Forms::Base`, and live in [`app/forms/`](https://github.com/opf/openproject/tree/dev/app/forms).
- Lookbook previews and pattern documentation are maintained in [`lookbook/`](https://github.com/opf/openproject/tree/dev/lookbook).

## Source repositories

OpenProject maintains forks of the Primer libraries:

- [opf/primer_view_components](https://github.com/opf/primer_view_components): ViewComponents for the Primer Design System used in OpenProject.
- [opf/openproject-octicons](https://github.com/opf/openproject-octicons): SVG icons and their Ruby and Angular libraries.
