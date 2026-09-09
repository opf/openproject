# Migrating Jira and Confluence together

Many organizations run Jira and Confluence tightly linked — issues reference pages, pages embed live issue status. When migrating away from Atlassian, these links need to keep working, not just the data on either side.

## Principle

- **Links between the two keep working at all times**, except briefly during the moment an individual item is being migrated.
- Migrations of Jira and Confluence content can run on completely different timelines. You don't need to migrate both at once, or in lockstep, for links to stay intact.
- **OpenProject** is responsible for everything related to Jira and its content and migration.
- **XWiki** is responsible for everything related to Confluence and its content and migration.


## Your options for Confluence

| Your situation                                              | What happens                                                 |
| ----------------------------------------------------------- | ------------------------------------------------------------ |
| **You migrate Confluence to XWiki**                         | Links stay intact automatically via redirects, whether Jira and Confluence migrate together or on separate schedules. See below. |
| **You keep Confluence** (only migrating Jira)               | An OpenProject–Confluence integration lets your Jira → Confluence links keep working unchanged. *(In development.)* |
| **You migrate Confluence to another tool**                  | Not currently supported.                                     |

Note: the rest of this guide covers the first scenario (migrating Confluence to XWiki alongside Jira) only. 

## Goal

Today, Confluence and Jira are tightly integrated — issues link to pages and vice versa. After migration, XWiki and OpenProject provide that same level of integration. Links between the two keep working throughout the transition, not just once both migrations are complete.

```mermaid
flowchart TB
    subgraph Source["Source (today)"]
        direction LR
        Confluence["Confluence"]
        Jira["Jira"]
        Confluence <--> Jira
    end
    subgraph Target["Target (after migration)"]
        direction LR
        XWiki["XWiki"]
        OpenProject["OpenProject"]
        XWiki <--> OpenProject
    end
    Source --> Target

    classDef atlassian fill:#e9f0fb,stroke:#0052CC,stroke-width:1px,color:#0052CC;
    classDef openproject fill:#e8eef2,stroke:#0D4A73,stroke-width:1px,color:#0D4A73;
    classDef xwiki fill:#e6f4fa,stroke:#0087CB,stroke-width:1px,color:#0087CB;
    classDef neutral fill:#FFFFFF,stroke:#000000,stroke-width:1px,color:#000000;

    class Confluence,Jira atlassian
    class OpenProject openproject
    class XWiki xwiki
    class Source,Target neutral
```

Because the two migrations run independently, a link between an issue and a page can be in any of four states at any given time — and different links can be in different states simultaneously:

|                             | **Confluence** (not yet migrated)                         | **XWiki** (migrated)                              |
| --------------------------- | --------------------------------------------------------- | ------------------------------------------------- |
| **Jira** (not yet migrated) | Unchanged — works as it always has                        | Jira issue links to a page already moved to XWiki |
| **OpenProject** (migrated)  | OpenProject work package links to a page not yet migrated | Both sides migrated — the end state               |

All four combinations work without any manual intervention.

## How links stay intact during migration (Confluence → XWiki case)

Migration happens in two steps, and you control when the second one runs:

**Step 1 — Migrate content, keep old links working.**
A redirect component is added at both the Jira and the Confluence address. Every request to either address is automatically routed to the right place: to the original system if the content hasn't moved yet, or to the new system if it has. For example, if a Confluence page links to `jira.company.com/browse/FOO-1` and that issue has since been migrated, the redirect component sends the reader straight to the corresponding OpenProject work package instead — no broken link, no page edit required. This works the same way in reverse, and regardless of whether Jira and Confluence migrate together or on entirely separate schedules.

At the same time, each side's native integration is swapped for its equivalent on the new system: Confluence's built-in Jira integration is replaced by XWiki's Jira plug-in, and Jira's built-in Confluence integration is replaced by OpenProject's Confluence integration. This keeps cross-references (like an issue embedded in a page) rendering correctly throughout the transition, not just plain links.

```mermaid
flowchart TB
    C["<b>Confluence</b>"]
    R{"<b>Redirect Component</b><br/>Has issue <code>FOO-1</code> been<br/>migrated yet?"}
    O["<b>OpenProject</b>"]
    J["<b>Jira</b>"]
    Done(["content of <code>FOO-1</code>"])

    C -->|calls link to <code>https://jira.company.com/browse/FOO-1</code>| R
    R -- "Yes" --> O
    R -- "Not Yet" --> J
    O -->|serves the migrated work package| Done
    J -->|serves <code>FOO-1</code> as it always has| Done

    classDef atlassian fill:#e9f0fb,stroke:#0052CC,stroke-width:1px,color:#0052CC;
    classDef openproject fill:#e8eef2,stroke:#0D4A73,stroke-width:1px,color:#0D4A73;
    classDef neutral fill:#f5f5f5,stroke:#333,stroke-width:1px,color:#333;

    class C,J atlassian
    class O openproject
    class Done,R neutral
```

**Step 2 — Update links to their final destination (optional, on demand).**
Once you're ready, an admin can trigger a cleanup step that rewrites old links to point directly at their final destination — e.g. straight to the OpenProject work package or XWiki page, instead of via the redirect. This step can run incrementally and independently on either side — you don't need both systems ready at once, and you can do it project by project or space by space. This is optional: everything already works without it.

```mermaid
flowchart
    subgraph Source["Source"]
      direction LR
      subgraph OPC["OpenProject"]
          OPCI["Confluence integration"]
      end
      subgraph XW1["XWiki"]
          XW1I["OpenProject plug-in"]
      end
      
      OPC <--> XW1
    end

    subgraph Target["Target"]
      direction LR
      subgraph OPXW["OpenProject"]
          OPXWI["XWiki integration"]
      end
      subgraph XW2["XWiki"]
          XW2I["OpenProject plug-in"]
      end
      OPXW <--> XW2
    end

    Source -->|<b>Rewrite Links</b><br/><code>confluence.com/pages/65538</code> => <code>xwiki.com/Space/Page</code>| Target

    
    classDef atlassian fill:#e9f0fb,stroke:#0052CC,stroke-width:1px,color:#0052CC;
    classDef openproject fill:#e8eef2,stroke:#0D4A73,stroke-width:1px,color:#0D4A73;
    classDef xwiki fill:#e6f4fa,stroke:#0087CB,stroke-width:1px,color:#0087CB;
    classDef atlassian fill:#e9f0fb,stroke:#0052CC,stroke-width:1px,color:#0052CC;
    classDef neutral fill:#FFFFFF,stroke:#000000,stroke-width:1px,color:#000000;

    class OPC,OPXW,XW1I,XW2I,R openproject
    class OPCI atlassian
    class XW1,XW2,OPXWI xwiki
    class Source,Target neutral
```

## Current limitations

- **Confluence pages that embed live search results from Jira** (via JQL) have limited support today. Mapping these to an equivalent OpenProject filter is planned but not yet finalized.
- **Distinguishing whether a link should point at Confluence or XWiki** during the transition period is being refined, since the two systems return different content for the same kind of link.
- The **OpenProject Confluence integration** is still in development.
