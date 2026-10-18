---
status: "proposed"
date: 2026-06-23
decision-makers: OpenProject Development Team
consulted:
informed: All developers
---

# AI-assisted pull request reviews

## Context and Problem Statement

AI reviewers such as GitHub Copilot now leave comments on our pull requests, and
locally run large language models (LLMs) are increasingly used to generate review
feedback that developers paste into a PR. These tools can be helpful, but we have
no shared understanding of how to use them. Today it is unclear who is allowed to
trigger an AI review, whether AI comments must be acted upon, who is accountable
for the resulting noise, how this works when a PR crosses team boundaries, and how
to treat review feedback produced by a local LLM.

How should AI-assisted reviews be requested, owned, and acted upon on our pull
requests, so that they add value without becoming unsolicited noise or eroding the
accountability that human review provides?

## Decision Drivers

- AI review should augment human review, never replace it.
- Avoid unsolicited AI feedback being imposed on someone else's pull request.
- Keep clear human ownership and accountability for every comment on a PR.
- Respect team boundaries; what is normal within a team may not be welcome across teams.
- We cannot technically prevent someone from pasting a local LLM review into a PR, so
  we need a shared norm rather than a technical gate.
- Keep the process lightweight and free of per-PR ceremony where trust already exists.

## Considered Options

- Ad-hoc / free-for-all (current practice): anyone may trigger an AI review at any time,
  with no shared rules about ownership or follow-up.
- Ban AI reviews entirely.
- Opt-out: AI review is allowed by default, and an author must explicitly decline it.
- Opt-in by mutual agreement: AI review happens only when both author and reviewer agree
  to it, and a human reviewer takes ownership of the AI's comments.

## Decision Outcome

Chosen option: **"Opt-in by mutual agreement"**, because it keeps AI review as a
deliberate, consented addition on top of human review while preserving clear human
accountability for everything that lands on a pull request.

The current ad-hoc approach was rejected because it lets AI feedback be imposed on a
PR without the author's consent and leaves no one accountable for filtering false or
low-value comments. A full ban was rejected because these tools do provide value when
used deliberately, and a ban would be hard to enforce given locally run LLMs. Opt-out
was rejected because it still defaults to imposing AI review on people who have not
asked for it, placing the burden on authors to decline.

The decision rests on a few concrete rules:

- **Only directly involved people request AI review.** The PR author or an assigned
  reviewer may request it. People who are not involved in the PR should not request an
  AI review on it; AI review is not a way to weigh in on work you are not reviewing.
- **AI review is on top of human review, never a replacement for it.** A PR is never
  considered reviewed solely because an AI commented on it.
- **AI comments are not, by themselves, calls to action.** A Copilot comment does not
  obligate the author to change anything until a human reviewer stands behind it.
- **A human reviewer speaks for the AI.** The reviewer who requested or accepted the AI
  review takes ownership of its comments and triages each one:
  - 👍 if the AI's comment appears correct and worth addressing;
  - 👎 plus a comment, or resolving the thread, if it is not;
  - say so plainly when uncertain, e.g. _"not sure about this, please double check."_

  In short: **treat an AI comment as if you had written it yourself.**
- **Within a team, this is implicit.** Teams that already work this way do not need to
  re-confirm the agreement on every PR. **Across teams, confirm first** before requesting
  an AI review on another team's pull request.
- **Local LLM reviews pasted into a PR** cannot be prevented, so we accept that they
  happen. The person pasting such feedback must review and filter it before posting it,
  and takes ownership of it exactly as for any other AI comment. When in doubt, ask the
  people on the PR whether they are okay with it first.

### Confirmation

This is primarily a social norm rather than something a tool can enforce. Compliance is
confirmed by:

- A reviewer being identifiable as the owner of every AI comment thread on a PR
  (via 👍 / 👎 and follow-up comments), so AI feedback is never left unattended.
- A reference to this ADR from the code review guidelines.
- Authors and reviewers raising it directly when an AI review appears that was not
  agreed upon, especially across teams.

## Pros and Cons of the Options

### Ad-hoc / free-for-all (current practice)

- Good, because it requires no process and no agreement.
- Neutral, because it allows useful AI feedback to surface.
- Bad, because AI feedback can be imposed on a PR without the author's consent.
- Bad, because no one is accountable for filtering false or low-value comments.
- Bad, because it provides no guidance for cross-team situations.

### Ban AI reviews entirely

- Good, because it removes all AI-generated noise from PRs.
- Good, because accountability stays entirely with human reviewers.
- Bad, because it discards genuine value these tools provide when used deliberately.
- Bad, because it is effectively unenforceable given locally run LLMs.

### Opt-out

- Good, because AI review is available by default without per-PR negotiation.
- Neutral, because authors retain a way to decline.
- Bad, because it still defaults to imposing AI review on people who did not ask for it.
- Bad, because it puts the burden on authors to opt out rather than on requesters to agree.

### Opt-in by mutual agreement

- Good, because AI review is a deliberate, consented addition rather than an imposition.
- Good, because a human reviewer always owns and triages the AI's comments.
- Good, because it scales down to zero ceremony within a trusting team.
- Good, because it gives clear guidance for cross-team requests and pasted local LLM reviews.
- Neutral, because it relies on shared discipline rather than tooling to enforce.
- Bad, because reviewers must spend effort triaging AI comments they stand behind.

## More Information

This decision concerns the etiquette of AI-assisted review and does not mandate or
endorse any particular AI tool (any such choice would likely become stale quickly).
It assumes such tools are already in use and defines how we handle their output
responsibly.

The guiding principle is accountability: a human reviewer stands behind every comment on
a pull request, whether they typed it themselves or an AI did. This decision should be
revisited if the capability or reliability of AI reviewers changes substantially, or if
the social norm proves insufficient and a technical gate becomes warranted.
