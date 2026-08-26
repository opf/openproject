---
sidebar_navigation:
  title: Custom fields migration
description: Migration of Jira custom fields to OpenProject during a Jira Data Center migration. Supported field types, edge cases, and limitations.
keywords: Jira custom fields, OpenProject custom fields, field type mapping, field contexts, unsupported field types
---

# Custom fields migration from Jira to OpenProject

The Jira Migrator automatically detects custom fields that are actually used in your imported issues, and 
creates matching OpenProject custom fields for them. 
Fields that exist in Jira but contain no values in any imported issue are ignored.

All newly created custom fields are placed in a **Jira import** group in the work package form configuration and 
are not assigned to any existing project by default.

## Supported field types

The following Jira custom field types are imported:

| Jira field type              | OpenProject field type | 
|------------------------------|------------------------|
| Single select                | List                   | 
| Radio buttons                | List                   | 
| Multi-select                 | List                   | 
| Checkboxes                   | Boolean or List        |  
| Text field                   | Text (short)           | 
| Text area                    | Text (long)            | 
| Date picker                  | Date                   | 
| Date Time Picker             | Date — **the time-of-day is not migrated, only the date** (planned: [JIM-1](https://community.openproject.org/projects/JIM/work_packages/JIM-1)) | 
| Number                       | Float                  |  
| URL                          | Link (URL)             |  
| User picker                  | User                   |
| Multi-user picker            | User                   |               
| Cascading select             | Hierarchy or List      | 
| Labels                       | List                   | 

Read more about [OpenProject custom field formats](../../../system-admin-guide/custom-fields/#custom-field-formats) and 
the [Hierarchy format](../../../system-admin-guide/custom-fields/#hierarchy-custom-field-enterprise-add-on) in particular in the system administration guide.

## Currently unsupported field types

Jira custom field types not listed above are skipped. This includes, but is not limited to, the following fields. (See [JIM-55](https://community.openproject.org/projects/JIM/work_packages/JIM-55/activity)) for details):

- Version fields
- Sprint assignment
- Epic links
- Story points
- Third-party plugin fields, with the possible exception of a ScriptRunner scripted field reporting a datetime
  return type — see [Date Time Picker](#date-time-picker) below

If a field is skipped, its values are not imported and no OpenProject custom field is created for it.



## Field type details and edge cases

### Checkboxes

Jira checkbox fields (`multicheckboxes`) behave differently depending on how many options the field has in the imported data:

- **Single option**: The field becomes an OpenProject **Boolean** (yes/no) custom field named `<FieldName> - <OptionValue>`. It is `true` if the issue had that option checked.
- **Multiple options**: The field becomes a multi-value **List** custom field containing all checked values.

If a checkbox field has different option sets across projects (via Field Contexts), both rules above apply independently per context group. 
A single Jira checkbox field can result in multiple OpenProject custom fields.

### Cascading select

Jira cascading select fields have two import modes depending on your OpenProject edition:

- **Enterprise edition (custom field hierarchies are enabled)**: The field is imported as an OpenProject **Hierarchy** custom field. 
  The full parent-child tree is preserved. A selected value of `Animals > Cat` is stored as the `Cat` item under the `Animals` parent.
- **Community edition**: The field is imported as a **List** custom field. 
  The option list is flattened and each level is stored as a full path string. For example, `Animals > Cat` produces both `Animals` and `Animals / Cat` as separate list options. 
  The selected value on each issue becomes the deepest matching path.

### Date Time Picker

> **This is not a 1:1 migration.** Jira's Date Time Picker custom field type is imported as an OpenProject **Date**
> custom field, and the time-of-day component is dropped entirely — only the date carries over. If the exact time
> matters for your data, do not assume this field migrates cleanly.

A ScriptRunner scripted field that reports a datetime return type in Jira's field metadata will also be picked up
and imported the same way, as a Date field. This is based only on the field's reported type, not on any
ScriptRunner-specific handling — the actual value a script produces at runtime can vary, and whether it converts
into a usable date has not been verified. If you use ScriptRunner fields, test this specifically with your own
data before relying on it. Scripted fields reporting any other return type are not supported.

### Labels and lists

Jira Labels fields and any String list custom fields do not expose all their allowed values within [Field contexts](#field-contexts) through the Jira API. 
Instead, the migrator scans all imported issues and collects every distinct string value actually used. 
These collected values become the option list for a single multi-value List custom field in OpenProject.

Values that do not appear in any issue are not added to the option list.

This applies only to a custom field of type Labels. Jira's standard Labels field, present by default on every
issue, is a system field rather than a custom field and is not covered by this or any other part of the custom
field migration.

### Option lists with incomplete allowed values

The Jira API only reports the options a field currently offers on an issue's edit screen. Options removed from a field 
context after issues were set - and fields that sit on no edit screen at all - therefore report no allowed values, or 
fewer than the imported issues actually use.

To avoid losing those values, the migrator also collects the options found on the imported issues themselves and adds 
any that the API did not report to the option list of the custom field the issue is imported into. This applies to 
single select, radio button, multi-select, checkbox and cascading select fields.

### Text areas and wiki markup

Jira text area fields store content in Jira wiki markup format. The migrator automatically converts this markup to OpenProject's Markdown format. 
The conversion covers common elements (headings, bold, italic, links, code blocks, tables), but plugin-specific markup may not convert perfectly.

### User fields

User picker and multi-user picker fields are resolved by matching the Jira user key to a user who is a member of the migrated project.
If the Jira user was not imported because they are not a member of any selected project, the user reference is dropped for that field value.

### Field contexts

In Jira Data Center, a single custom field can have different allowed values in different projects or for different issue types, via **Field Contexts**. 
The migrator handles this as follows:

- Each distinct set of allowed values becomes a **separate OpenProject custom field**.
- If multiple context groups are detected for one Jira field, each resulting custom field is named `<FieldName> (<ProjectKey>)` to disambiguate.
- If all contexts share the same allowed values, a single custom field is created without a project suffix.
- Field contexts are not available with their values via the API.
  The migrator uses project keys as suffixes to disambiguate contexts, but the original context names are not preserved.

During issue import, each issue is matched to the context whose projects and issue types fit. 
If no context matches (for example, the field was removed from a screen after values were set), the first available context is used as a fallback so no data is silently lost. 
The custom field an issue resolves to is activated in that issue's project, whether it was matched or used as a fallback.

### Deduplication with existing custom fields

If an OpenProject custom field with the same name and format already exists (from a previous import run or created manually), 
the migrator reuses it instead of creating a duplicate. The existing custom field is linked to the import and its values are preserved.

For **Hierarchy** and **List** fields, deduplication is not attempted because option lists may differ - a new custom field is always created for these types.
This applies every time the import runs, not just once: if you migrate in separate batches, each batch creates its own new
Hierarchy or List fields rather than reusing ones a previous batch already created, even when the option values are identical. 

If a name collision exists but the formats differ, the migrator appends a numeric suffix to the new field name (e.g., `My Field (2)`).

This is a separate mechanism from the option merging described under [Field contexts](#field-contexts) above, which only
combines identical option sets *within a single import run*. Deduplication decides whether to reuse a field that already
exists before that run starts; it does not retroactively affect how contexts were grouped during the run itself.

Note that the deduplication behavior is under active development and that the number of duplicated fields will be reduced in the future (tracked by [JIM-170] (https://community.openproject.org/projects/JIM/work_packages/JIM-170/activity).
