# Vote-based agenda sorting MVP

Open a meeting's action menu and select **Sorting mode** to choose **Manual**
or **Vote-based**. Changing this setting requires `edit_meetings`.

In vote-based mode, agenda items show their net vote score in the body. Anyone
with `view_meetings` can use **Upvote** and **Downvote** in an item's action menu.
Small thumbs-up and thumbs-down buttons also appear when hovering or focusing
the score line. On touch devices, these buttons remain visible.
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
