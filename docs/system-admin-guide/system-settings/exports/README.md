---
sidebar_navigation:
  title: Exports
  priority: 960
description: Exports in OpenProject.
keywords: export, csv, security
---
# Exports

## Limit work packages export

To set the limit of work packages or projects that can be exported, enter a desired number in the field and **save** your changes.

## Escape control characters in CSV exports

This setting is **enabled by default**. It helps to make exported CSV files safe and secure  to open in spreadsheet applications.

When enabled, values that start with certain control characters such as `=`  `@`  `\t`  `\r`  or  **`-`** and  **`+`**  are modified so they are treated as text instead of formulas. Unless, these values are deliberately exported as a number (-5.00) or currency (-1.234,56 €), they are not modified.

To disable this setting, clear the check-box and **save** your changes.

![Escape formula in csv exports under exports section in system settings](openproject_system_settings_exports.png)

> [!IMPORTANT]

There is no standard way to prevent CSV formula injection. Enabling this setting modifies exported values to provide an additional layer of security when CSV files are opened in spreadsheet applications.
