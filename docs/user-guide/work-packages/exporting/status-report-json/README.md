---
sidebar_navigation:
  title: Status report JSON
description: Download a machine-readable project status report from a work package
---

# Status report JSON

Open the reporting work package and select **More → Download status JSON**. The action is available when the **Status Report** export template is enabled for the work package type variant and you can export the work package. The file is downloaded as `status-report-<work package ID>.json` with media type **application/json**.

Set **Project progress (%)** under **Project settings → General → Status**. Enter a whole number from 0 to 100 or leave the field empty. The same project value appears in the PDF and JSON exports.

## Format 0.1

| Property | Source and meaning |
| --- | --- |
| `format`, `formatVersion` | Format identifier `openreport` and specification version `0.1`. |
| `source` | Source system name and a namespace based on the OpenProject installation UUID. |
| `project` | The project that owns the report work package. Includes its ID, identifier, name, Markdown description, status code, optional progress percentage, and configured project attributes. |
| `report` | The report work package ID and display identifier, title, Markdown summary, workflow status, period dates and configured report fields. |
| `sections` | Ordered embedded tables from the type variant. Each section has a configuration key, its configured name and the work packages matching the table and directly linked to the report. |

IDs are strings. Use the source namespace, the object type and the ID together to identify an object. Use the display identifier and name for presentation. A work package can appear in several sections with the same ID. Map local project identifiers and custom fields to their counterparts in the receiving system.

`period.start` and `period.end` come from the report work package's start and finish dates. An unset date or progress value is represented by `null`. Work package dates use `YYYY-MM-DD`. Status labels are for display. The project status code, such as `at_risk`, is for machine processing.

Each custom field entry has an `id`, `name`, `fieldType` and `value`. Values can be strings, numbers, booleans, references or arrays for multi-valued fields. A reference includes an ID and a display name, plus a kind for people, groups, versions and hierarchy items. Empty field values are omitted. The export follows the requesting user's permissions and includes custom columns configured for the selected embedded table.

A download captures the current values. Published report revisions, changes since the previous period and delivery by email are planned separately.

## Example

```json
{
  "format": "openreport",
  "formatVersion": "0.1",
  "source": {
    "system": "OpenProject",
    "namespace": "urn:uuid:2ee2b816-2333-4052-85e1-ff10012ab901"
  },
  "project": {
    "id": "17",
    "identifier": "lindenhof-elektro",
    "name": "Gewerk Elektro",
    "description": "Elektroinstallation für Gebäudeteil A.",
    "status": "at_risk",
    "progressPercent": 60,
    "attributes": [
      {
        "id": "23",
        "name": "Projektleitung",
        "fieldType": "user",
        "value": { "id": "4711", "name": "Max Mustermann", "kind": "person" }
      }
    ]
  },
  "report": {
    "id": "43",
    "identifier": "ELEKTRO-43",
    "title": "Statusbericht November",
    "period": { "start": "2026-11-01", "end": "2026-11-30" },
    "workflowStatus": { "id": "2", "name": "Submitted" },
    "summary": "Schutzrelais sind verspätet.",
    "attributes": []
  },
  "sections": [
    {
      "id": "query_9",
      "name": "Meilensteine",
      "items": [
        {
          "id": "44",
          "identifier": "ELEKTRO-44",
          "title": "Inbetriebnahme",
          "type": { "id": "3", "name": "Milestone" },
          "workflowStatus": { "id": "1", "name": "New" },
          "startDate": null,
          "dueDate": "2026-12-21",
          "attributes": []
        }
      ]
    }
  ]
}
```
