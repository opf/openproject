# OpenProject Risk Management

This bundled module adds risk-management functionality to OpenProject.

The module provides an administration page for selecting the work package type
used for risks and the work package custom fields used for probability, impact,
and category. Projects can enable a dedicated risk log with a risk matrix,
quick filters, a work package list, and a split detail view.

## Risk log dashboard concept

The dashboard combines complementary views below the quick-filter toolbar:

- The risk matrix supports spatial assessment and direct filtering by
  likelihood and impact. It deliberately has no card border or visible heading
  so the matrix remains the dominant visual element.
- The activity widget reports risks created or moved to Evaluated, Mitigation
  planned, Monitored, Occurred, or Rejected during a selectable relative
  time horizon. Its standard Primer action menu follows the relative period
  pattern used by baseline comparison.
- A stacked Chart.js chart groups the current risk statuses by category.
- A Primer progress bar summarizes the response statuses and excludes New.

The matrix and overview use a responsive two-column grid and stack vertically
on narrower viewports. The selected matrix cells and axis filters are exposed
visually and through their accessible pressed or checked states.

The risk workflow contains New, Evaluated, Mitigation planned, Monitored,
Occurred, and Rejected. Every transition between those statuses is allowed;
the final three statuses are closed.

Risk seed data uses English names independent of the interface language. The
basic-data seeder also updates the former German category field and option
values in place, preserving the configured field instead of creating a second
one.
