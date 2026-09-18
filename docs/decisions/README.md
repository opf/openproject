# Architecture Decision Records (ADRs)

This project uses **Architecture Decision Records (ADRs)** to document important technical and architectural decisions. ADRs ensure that we preserve context, reasoning, and trade‑offs so that current and future developers understand _why_ the system looks the way it does — not only _how_ it works.

An ADR becomes part of the project’s architecture documentation and is authoritative once accepted and merged.

---

## Where ADRs live

All ADRs are stored in the repository under:

```
/docs/decisions/
```

The ADR template is located at:

```
/docs/decisions/adr-template.md
```

---

## When an ADR is required

You must create an ADR when making a decision that is:

- Architectural or system‑wide
- Difficult to reverse
- Expensive to change later
- Introducing or replacing a technology
- Introducing a new RubyGem or NPM package when it is not trivial and introduces new usage patterns (e.g. Angular, React, dry-rb, etc.)
- Introducing a new database or service that needs to be included in the deployment process
- Introducing dependencies on external services
- Affecting APIs or system boundaries
- Influencing how multiple teams work

Typical examples:

- Introducing a framework or library
- Database technology decisions
- Authentication or authorization approach
- Service boundaries or modularization
- Communication patterns (events vs REST, sync vs async)
- Deployment or hosting strategy

If unsure: **create an ADR**. It is better to document one decision too many than one too few.

---

## Creating a New ADR (Step‑by‑Step)

1. **Copy the template**

   Copy the file:

   ```
   /docs/decisions/adr-template.md
   ```

2. **Choose the next number**

   ADRs are numbered sequentially.

   Format:

   ```
   adr-XXXX-short-title.md
   ```

   Example:

   ```
   adr-0005-use-dry-monads-for-services.md
   ```

   Use the next available number in the directory. If a different decision is being made in parallel, coordinate to avoid conflicts.

3. **Fill out the ADR**

   Fill in as many sections as possible. It is acceptable if some sections evolve during discussion — the pull request is part of the decision process.

4. **Open a Pull Request**

   Create a pull request containing only the ADR (and related material if necessary).

5. **Notify the team**

   Post a message in the **Development Matrix channel** announcing the proposed ADR.

6. **Request collaboration**

   If specific developers have expertise, explicitly request their input and collaboration.

7. **Add to Dev Weekly agenda**

   Add an agenda item to the next [weekly dev meeting](https://community.openproject.org/projects/development/recurring_meetings/2).

8. **Discuss and refine**

   Use pull request comments and the meeting discussion to refine the ADR.

9. **Confirmation steps**

   If the ADR includes Confirmation steps, ensure that you create a work package within OpenProject to implement these steps as soon as possible. Link the ticket in the Pull Request description.

10. **Approval**

    Be accepted through a pull request that gives every team the opportunity to review, with final approval by consensus among the team leads, then merged into the `dev` branch.

11. **Merge**

    Once approvals are present, the ADR can be merged.

---

## After Merge

When an ADR is merged:

- The decision becomes **mandatory** for the entire development team
- All developers must follow it
- Pull request reviewers should actively point out violations
- If the ADR contained Confirmation steps, these should be implemented as soon as possible

An ADR is not a suggestion — it is a documented team decision.

---

## Updating or Reversing a Decision

Accepted ADRs are **immutable**.

Do **NOT** edit the historical decision except for minor typos.

If a decision changes:

1. Create a new ADR
2. Reference the previous one
3. Mark the old ADR as _superseded_ in the status header
4. Move the ADR to the `/docs/decisions/archived/` directory as part of the pull request that introduces the new ADR.

Architecture history must remain traceable.

---

## ADR Status Values

Typical values:

- `accepted` — approved and binding
- `superseded by ADR-XXXX` — replaced by a newer decision

---

## How to Write a Good ADR

An ADR should explain the reasoning clearly enough that a developer, years later (yes, this includes yourself), understands the decision without asking the original authors.

Focus on:

- trade‑offs
- constraints
- alternatives considered
- why other options were rejected

Avoid writing only the solution. The **reasoning** is the most important part.

---

## Explaining the Template Sections

Below is guidance for each section of the template.

### Metadata Header

**status**
Current state of the ADR (accepted, superseded)

**date**
Last time the decision content changed.

**decision‑makers**
People responsible for making the decision.

**consulted**
People whose expertise was requested.

**informed**
People who should be aware but are not decision makers.

---

### Title

A short statement describing both the problem and the chosen solution.

Good:

> Use PostgreSQL as primary relational database

Bad:

> Database decision

---

### Context and Problem Statement

Describe:

- the situation
- what triggered the decision
- the problem being solved

Answer the question: **Why are we talking about this?**

This section should allow a reader to understand the decision without prior knowledge of the discussion.

---

### Decision Drivers

List the forces influencing the decision.

Examples:

- performance requirements
- scalability
- team expertise
- operational cost
- compliance
- maintainability

These are the evaluation criteria for the options.

---

### Considered Options

List realistic alternatives that were actually evaluated.

Include at least two options whenever possible.

Avoid strawman options.

---

### Decision Outcome

State the chosen option and _why it won_.

This is the most important section.

Someone should be able to read only this section and understand the conclusion.

---

### Consequences

Document what the decision causes.

Include both:

- positive effects
- negative effects

Every real decision has trade‑offs. Documenting the downsides prevents future confusion.

---

### Confirmation

Describe how we ensure the decision is followed.

Examples:

- code review checks
- automated tests
- linters
- architecture validation tools
- RuboCop rules
- Dangerfile checks
- Custom actions

---

### Pros and Cons of the Options

Explain the reasoning process for each option.

When the ADR is about introducing a package or a new coding pattern, show some code examples for each option so we can compare how the newly introduced pattern will be used.

This section answers the future developer’s question:

> Why didn’t we choose the other obvious solution?

---

### More Information

Optional supporting material:

- links
- meeting outcomes
- follow‑up work
- revisit conditions

---

## Review Responsibilities

All developers share responsibility for maintaining architectural consistency.

During PR reviews you should:

- check whether an ADR applies
- request an ADR if a major decision is introduced
- point out ADR violations

---

## Goal of ADRs

ADRs exist to save time, not to add process.

They exist to:

- prevent repeated debates
- speed up onboarding
- enable confident refactoring
- preserve architectural knowledge

If you are unsure whether to write one — write one.
