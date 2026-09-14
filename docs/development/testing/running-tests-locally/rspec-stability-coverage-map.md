# RSpec stability campaign: review and coverage map

This map accompanies the test-suite PR, which depends on the separate application correctness and frontend performance PR. It is not a claim of identical end-to-end coverage: rendered markup and query semantics can be tested below the browser, while JavaScript initialization and navigation still require feature tests.

## Review order

1. Shared browser helpers: Turbo/frame/stream completion, refindable elements, editor/menu readiness, driver compatibility.
2. Unit isolation: clocks, timezone fixtures, generated IDs, factory-default lifetime, and reloaded hierarchy state.
3. Custom-field administration and project fields: inspect replacement assertions alongside deleted or reduced browser scenarios.
4. Activities/meetings, project lists, work packages/scheduling, then module and administration flows.
5. CI and diagnostic tooling. Intermediate CI retains retries; disabling inline retries is a separate final PR after combined validation. The outer recovery pass remains a distinct mechanism.

## Coverage replacements

| Previous browser coverage | Direct coverage | Browser responsibility retained |
| --- | --- | --- |
| Custom-field administration class/format matrix (40 files listed below) | `spec/forms/custom_fields/details_form_spec.rb`: 47 class/format combinations, labels, input types, present/absent options, rendered widget markup | Representative format selection, navigation, list ordering/editing, project mappings and calculated-field flows. The form spec does not execute editor JavaScript. |
| Project custom-field display and editing combinations | `spec/components/open_project/common/inplace_edit_field_component_custom_fields_spec.rb`, `inplace_edit_field_dialog_component_custom_fields_spec.rb`; `modules/overviews/spec/components/overviews/project_custom_fields/item_component_spec.rb`; form-input, controller and model specs | Interactive editing and persistence; fixtures are scoped to the fields each browser scenario uses. |
| Project-list phase/comment cells and column/filter combinations | `spec/components/projects/row_component_spec.rb`; `spec/models/project_queries/static_spec.rb`; `spec/models/queries/projects/selects/custom_comment_spec.rb`; project phase/user-field query integration specs | List configuration, saved lists, help text and navigation. |
| Repeated activity permission/rendering combinations | `spec/components/work_packages/activities_tab/`; `spec/requests/work_packages/activities_tab_spec.rb`; `spec/services/add_work_package_note_service_spec.rb` | Comment editing, quoting, filtering, highlighting and scrolling. Empty-page stream regression coverage is in the prerequisite application PR. |
| Date-picker form and banner combinations | `spec/components/work_packages/date_picker/date_form_component_spec.rb`, `dialog_content_component_spec.rb`; `spec/controllers/work_packages/date_picker_controller_spec.rb` | Actual date selection, calendar interactions and persistence. Preview lifecycle tests stay with the application changes. |
| Gantt week-number expectations | `frontend/src/app/core/setup/init-locale.spec.ts` in the application PR checks English/German year-boundary rules | Timeline display and navigation remain browser-tested. |
| Filter parsing, relation/date operators, attachment/user-field semantics | `spec/lib/api/v3/queries/query_params_representer_spec.rb`, `query_payload_representer_spec.rb`; `spec/models/queries/`; relation API specs | Filter interaction and visible result updates. |
| PDF export option rendering | `spec/components/work_packages/exports/pdf/export_settings_component_spec.rb`, `report/export_settings_component_spec.rb`; PDF model coverage | Browser export initiation and download flows. |
| BIM navigation/viewer combinations | `modules/bim/spec/controllers/bim/ifc_models/ifc_viewer_controller_spec.rb` | Browser navigation, viewpoint interactions and viewer behavior remain covered by retained feature scenarios. |
| Repeated meeting, workflow and work-package creation setup | Consolidated feature scenarios plus existing model/component/request coverage; this is not uniformly a one-for-one migration | Assertions share setup/navigation where one coherent interaction sequence establishes the same behavior. Review the removed assertions alongside the retained flow. |

## Deleted custom-field matrix files

Every file below is replaced at the markup/option level by `spec/forms/custom_fields/details_form_spec.rb`. Repeated browser navigation and JavaScript initialization for every resource/format pair are intentionally no longer exercised.

- `spec/features/admin/custom_fields/groups/date_spec.rb`
- `spec/features/admin/custom_fields/groups/float_spec.rb`
- `spec/features/admin/custom_fields/groups/int_spec.rb`
- `spec/features/admin/custom_fields/groups/list_spec.rb`
- `spec/features/admin/custom_fields/groups/long_text_spec.rb`
- `spec/features/admin/custom_fields/groups/text_spec.rb`
- `spec/features/admin/custom_fields/projects/format_fields/boolean_spec.rb`
- `spec/features/admin/custom_fields/projects/format_fields/date_spec.rb`
- `spec/features/admin/custom_fields/projects/format_fields/float_spec.rb`
- `spec/features/admin/custom_fields/projects/format_fields/hierarchy_spec.rb`
- `spec/features/admin/custom_fields/projects/format_fields/integer_spec.rb`
- `spec/features/admin/custom_fields/projects/format_fields/link_spec.rb`
- `spec/features/admin/custom_fields/projects/format_fields/list_spec.rb`
- `spec/features/admin/custom_fields/projects/format_fields/long_text_spec.rb`
- `spec/features/admin/custom_fields/projects/format_fields/text_spec.rb`
- `spec/features/admin/custom_fields/projects/format_fields/user_spec.rb`
- `spec/features/admin/custom_fields/projects/format_fields/version_spec.rb`
- `spec/features/admin/custom_fields/projects/format_fields/weighted_item_list_spec.rb`
- `spec/features/admin/custom_fields/time_entries/boolean_spec.rb`
- `spec/features/admin/custom_fields/time_entries/date_spec.rb`
- `spec/features/admin/custom_fields/time_entries/float_spec.rb`
- `spec/features/admin/custom_fields/time_entries/integer_spec.rb`
- `spec/features/admin/custom_fields/time_entries/text_spec.rb`
- `spec/features/admin/custom_fields/time_entries/user_spec.rb`
- `spec/features/admin/custom_fields/time_entries/version_spec.rb`
- `spec/features/admin/custom_fields/users/boolean_spec.rb`
- `spec/features/admin/custom_fields/users/date_spec.rb`
- `spec/features/admin/custom_fields/users/float_spec.rb`
- `spec/features/admin/custom_fields/users/hierarchy_spec.rb`
- `spec/features/admin/custom_fields/users/int_spec.rb`
- `spec/features/admin/custom_fields/users/long_text_spec.rb`
- `spec/features/admin/custom_fields/users/text_spec.rb`
- `spec/features/admin/custom_fields/versions/boolean_spec.rb`
- `spec/features/admin/custom_fields/versions/date_spec.rb`
- `spec/features/admin/custom_fields/versions/float_spec.rb`
- `spec/features/admin/custom_fields/versions/int_spec.rb`
- `spec/features/admin/custom_fields/versions/list_spec.rb`
- `spec/features/admin/custom_fields/versions/long_text_spec.rb`
- `spec/features/admin/custom_fields/versions/text_spec.rb`
- `spec/features/admin/custom_fields/versions/user_spec.rb`
