# Vote-based agenda sorting MVP

The sidebar shows **Sorting mode**. Use **Change sorting mode** there or select
**Sorting mode** in the meeting's action menu to choose **Manual** or **Vote-based**.
Changing this setting requires `edit_meetings`.

In vote-based mode, agenda items show their net vote score in the body. Anyone
with `view_meetings` can use **Upvote** and **Downvote** in an item's action menu.
The **Votes: N** line and small thumbs buttons appear when hovering or focusing
the agenda item. On mobile and touch devices, both remain visible.
Selecting the current vote removes it; selecting the opposite vote replaces it.
Each user can have one vote per item.

Items are ranked within their section by upvotes minus downvotes, descending.
Ties use the existing manual position and then the item ID. Sections remain
manually sorted. Item drag/drop and positional move actions are unavailable in
vote-based mode; moving an item to another section remains available.

Switching back to manual restores the manual positions and hides the votes.
Votes are retained when switching modes or moving between sections. Copies and
new recurring occurrences inherit the sorting mode and start without votes.
Moving an item to another meeting resets its votes.

Voting is available in draft, open, and in-progress meetings. Closed and
cancelled meetings, templates, and backlogs do not accept votes. Backlogs retain
manual ordering. The meeting page, presentation navigation, PDF agendas and
minutes, and API agenda collections use the same effective ordering.

The voter receives an immediate Turbo update. Other viewers use the existing
meeting update notification; presentation mode refreshes through existing
polling. Closed rankings are calculated from retained reactions, so deleting a
voter can affect their historical score and ranking.

Apply `20261006120000_add_vote_based_agenda_sorting.rb` before trying the feature.
The migration adds the mode, reaction-change timestamps, and database constraints
that restrict agenda-item reactions to one upvote or downvote per user.

A dedicated voting permission, voter lists, separate upvote/downvote totals,
and a frozen historical ranking are outside this MVP.

## API v3

Meetings expose `agendaSortingMode` as a string: `manual` or `vote_based`.
Set it on creation or via `PATCH /api/v3/meetings/:id` with the current
`lockVersion`. Changing the mode requires `edit_meetings`. The meeting schema
lists the two allowed values; other values are rejected with HTTP 422.

Agenda items expose a read-only `voteScore` and, when voting is available,
`upvote` and `downvote` action links. Call either action without a request body:

- `POST /api/v3/meeting_agenda_items/:id/upvote`
- `POST /api/v3/meeting_agenda_items/:id/downvote`

The same actions are available below
`/api/v3/meetings/:meeting_id/agenda_items/:id`. Each action toggles that vote,
just like the UI: repeating it removes the vote, and the opposite action
replaces it. HTTP 200 returns the updated agenda item, including its score.
Voting requires only `view_meetings`, not `manage_agendas`.

Both actions return HTTP 400 when the meeting uses manual sorting, without
changing existing votes. Other voting restrictions return HTTP 403; missing
or invisible resources (including cancelled meetings) return HTTP 404.
