# OpenProject CDE Plugin
# ISO 19650-compliant Common Data Environment for OpenProject

## Overview

This plugin extends OpenProject with ISO 19650-compliant CDE (Common Data Environment) capabilities.

## Features

- **Information Containers**: Governed information objects with unique identifiers
- **Revision Management**: Working revisions with immutability rules
- **Lifecycle States**: WIP → Shared → Published → Archived
- **Metadata Governance**: Controlled vocabularies for discipline, originator, classification
- **Suitability Assignment**: S0, S1, S2, A1, A2, D1 codes per ISO 19650
- **Publication Gate**: Enforce preconditions before publishing
- **Audit Trail**: Append-only, immutable audit events
- **Exchange Packages**: Formal information exchange (Slice 11)
- **Transmittals**: Traceable delivery records (Slice 12)
- **Compliance Rules**: Automated governance checks (Slice 13)
- **Governance Dashboards**: KPI reporting (Slice 14)

## Installation

1. Add the plugin to your OpenProject installation:
   ```bash
   bundle install
   bundle exec rake openproject:plugins:install
   ```

2. Run migrations:
   ```bash
   bundle exec rake db:migrate
   ```

3. Enable the plugin in OpenProject configuration.

## Configuration

Edit `config/cde_conventions.yml` to customize:
- Container identifier format
- Status codes
- Suitability codes
- Publication preconditions
- Permission matrix

## Vertical Slices

| Slice | Capability | Status |
|-------|-----------|--------|
| 0 | Platform Foundation | ✅ Complete |
| 1 | Create Information Container in WIP | ✅ Complete |
| 2 | Manage Working Revision | ✅ Complete |
| 3 | Metadata Governance and Search | ✅ Complete |
| 4 | Lifecycle State Management | ✅ Complete |
| 4.5 | BIM Context Linking | ⏳ Pending |
| 5 | Suitability Assignment | ✅ Complete |
| 6 | Review, Approval and Publication | ✅ Complete |
| 7 | Revision After Publication | ⏳ Pending |
| 8 | BCF Traceability | ⏳ Pending |
| 9 | Published Information Consumption | ⏳ Pending |
| 10 | Archive Lifecycle | ⏳ Pending |
| 11 | Exchange Packages | ⏳ Pending |
| 12 | Transmittals | ⏳ Pending |
| 13 | Compliance Rules | ⏳ Pending |
| 14 | Governance Dashboards | ⏳ Pending |

## Architecture

The plugin follows the vertical slice pattern with:
- **Domain models**: Container, Revision, Metadata, Suitability, AuditEvent
- **Services**: Conventions, IdentifierValidator, PublicationGate
- **API**: RESTful API v3 with authorization
- **Tests**: Integration tests for all slices

## Compliance

This plugin implements ISO 19650 requirements for:
- Container identification and governance
- Revision management and immutability
- Lifecycle state management
- Metadata governance
- Suitability assignment
- Publication gates
- Audit trails

## Development

See `.agent/skills/vertical-slice-generator/` for slice scaffolding.

## License

GPL-3.0
