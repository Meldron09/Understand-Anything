# Research: how learn-anything reads a OneNote page

Ticket: Meldron09/Understand-Anything#12 (map: #1). Researched 2026-10-24 against primary sources only
(Microsoft Learn, Microsoft Support, Claude Code and Claude help docs). Nothing was installed and no
authenticated Microsoft or MCP tool was called. Where a primary source is silent the cell says **unknown**.

Terms: *source doc* = the normalized input learn-anything hands to the next stage; *handoff* = the contract
between skills (see `CONTEXT.md`). Constraints from the map: free/OSS and local only; local macOS Claude Code
is the primary target.

## Short answer

- Claude's Microsoft 365 connector **cannot read OneNote**: its own help page says "Other formats, including OneNote, can't be read." It also needs a work account and admin consent, so it is out.
- Microsoft's newer MCP offering (Work IQ) lists no OneNote support and is billed per use. Out.
- The Graph OneNote API works (personal and work/school accounts) and returns real page HTML plus image/file resources, but needs an app registration and delegated sign-in, and ink is not in the stable output.
- User export to PDF of a single page is the lowest-friction, fully local path on Mac. It is page-at-a-time.

## Comparison

| | M365 connector / MCP | Graph API direct | Export to PDF | Export to HTML | Export to .onepkg | Export to Word |
|---|---|---|---|---|---|---|
| **Text** | Not readable: OneNote unsupported [C1] | Yes, as HTML [G1][G2] | Static snapshot [E1]; selectable text **unknown** | No Microsoft doc found for HTML export. Closest: Windows "Single File Web Page (*.mht)" [E3] | Container of native sections; no source doc parses it for us. Parse via MS-ONE spec **unknown** effort [S1] | Yes on Windows desktop (.docx/.doc) [E3] |
| **Images** | n/a | Yes: `img` with `src` and `data-fullres-src`; binary via `resources/{id}/$value` [G2][G3] | Part of the page snapshot [E1] (inference: rendered visually) | **unknown** | Embedded in package; **unknown** how to extract | **unknown** |
| **Ink** | n/a | Not in stable output HTML docs [G2]. Beta `includeInkML=true` returns InkML multipart, but only in a 2017 archived blog, "some types of ink are not returned yet", not production ready [G4]. Current support **unknown** | Not documented. Expected to appear only as a visual (inference, untested): **unknown** | **unknown** | MS-ONE spec lists text, images, tables, note tags and other user-defined content [S1]; whether ink is stored and extractable is **unknown** | **unknown** |
| **Tables** | n/a | Yes, `table/tr/td`, nested allowed, no `rowspan`/`colspan` [G2] | Part of the page snapshot [E1] (inference: rendered visually) | **unknown** | Native | **unknown** |
| **Auth friction** | Work account + Entra tenant on a Business plan, Global Admin must approve; personal accounts cannot connect [C1]. In Claude Code, must be connected at claude.ai/customize/connectors, local OAuth is not supported [C2] | Delegated sign-in only; app-only auth removed 2025-03-31 [G5][G6]. Needs an app registration (setup steps not re-verified here); scopes `Notes.Read` (personal and work) [G7] | None | None | None | None |
| **Failure modes** | Silently cannot see OneNote content [C1]. Work IQ: no OneNote in listed data [W1] | Work/school: errors 10008/10013 when a document library has more than 5,000 / 20,000 items; 20166 throttling (429); 10004 password-protected section; 40001/40004 token or scope errors [G8]. Pages list defaults to 20, max 100 [G1]. Docs themselves warn of limits for backup/bulk use [G1] | **One page at a time**; no section or notebook to PDF in the web app [E2]; Mac: page by page [E4]. Snapshot goes stale [E1] | Not available on Mac or web per sources found | Mac: not supported, only Save as PDF (Microsoft employee, community answer, not primary) [Q1]. Whole-notebook export reported unavailable for work/school (community, not primary) [Q1] | Windows desktop only; "You can only export the current page or section" [E3]. Mac: only current page, as PDF [E3][E4] |
| **Offline / local** | No: cloud connector, needs network [C2] | No: calls Microsoft cloud each time. Content can be cached locally as a source doc after fetch | Yes, fully local after export | Yes if available | Yes | Yes |
| **Cost** | Free for Claude plans [C1]; Work IQ is usage-billed in Copilot Credits, so never a pick [W1] | No per-call price found in the docs read: **unknown** | Free | Free | Free | Free (needs Word) |

## Findings by option

### 1. Microsoft 365 connector (MCP)

- Claude help: the connector reads Word, Excel, PowerPoint, PDF and plain text from SharePoint/OneDrive. "OneNote isn't supported. Other formats, including OneNote, can't be read." Work accounts only; personal @outlook.com / @hotmail.com cannot connect; a Global Administrator must authorize first [C1].
- Claude Code fetches claude.ai connectors automatically when logged in with a claude.ai subscription [C2]. Anthropic-hosted connectors such as Microsoft 365 "don't support local OAuth from Claude Code" and must be connected at claude.ai/customize/connectors [C2]. Whether the connector's SharePoint/OneDrive file read could return a `.one` or `.onepkg` file is covered by the "can't be read" statement [C1].
- Microsoft's Work IQ MCP (Copilot Studio connector list, Work IQ docs) covers email, calendar, OneDrive/SharePoint documents, Teams, people, Planner, enterprise search. OneNote is not in the list [W1][W2]. It is billed through Copilot Credits [W1]. Microsoft Q&A says no first-party OneNote MCP exists, but that is a community thread [Q2]; I found no Microsoft Learn page documenting one.
- Verdict: no usable path. Not tested live (no authenticated calls made, by instruction).

### 2. Graph API direct

- Endpoint: `GET /me/onenote/pages/{id}/content` returns page HTML; `Accept: text/html` [G1][G7]. Works for personal Microsoft accounts and work/school accounts [G7][G9].
- Output HTML wraps content in a positioned div; keeps paragraphs, headings, lists, tables, note tags; images are `img` tags pointing at resource endpoints; files are `object` tags [G2]. OneNote also runs OCR on images server-side [G10], but the docs read do not say OCR text is returned on read: **unknown**.
- Deprecation: app-only (application) authentication is no longer supported since 2025-03-31 [G5][G9]. Delegated sign-in is the only way, so a local plugin needs an interactive browser or device-code login each session or a cached refresh token. No token-handling design here.
- Docs state that backup/restore of sections or notebooks hits API limits and point to OneDrive file-scan guidance instead [G1]. Pages-per-call limits as above [G1].
- Ink: see table. Treat as **not available** for planning.

### 3. User exports

- **PDF**: Windows desktop File > Export > PDF [E1]. Mac: File > Save as PDF, current page [E4]. Web: Mac browsers "Export as PDF"; Windows browsers use Print to PDF; "You can't export an entire notebook or section to PDF" [E2]. This is the only export Microsoft documents for Mac.
- **Word**: Windows desktop only, current page or section [E3].
- **HTML**: no Microsoft doc for HTML export found. Windows offers `.mht` [E3].
- **.onepkg / .one**: file format is publicly specified ([MS-ONE]) [S1]; I found no primary doc describing `.onepkg` export. Community answers (several threads, search-summarised, not primary) say Windows desktop only for notebooks, not Mac [Q1]. No free parser was evaluated here.

## Pick

**User export of a single page to PDF**, then treat the PDF as the source doc (the PDF handoff path).

Why: only option that is free, local, offline, and needs no Microsoft account plumbing; it is the one export
Microsoft documents on Mac [E4]; it should preserve layout, tables, images, and ink as the learner sees them (inference, untested). Cost:
manual page-by-page export, and whether PDF text is selectable (vs. needing OCR/vision) is **unknown**.

## Fallback

**Graph OneNote API, delegated auth, called directly (not via MCP)**, for learners who want a whole
section or need structured HTML with image binaries. Costs: one-time app registration, interactive
sign-in, cloud dependency, ink unsupported in practice, 5,000/20,000-item library errors on large work
libraries [G8]. Wrap it behind the same source doc handoff so the downstream skills never know which
path ran.

## Open items (not answerable from primary sources)

1. Is text in a OneNote PDF export selectable on Mac? (a one-page test would settle it)
2. Does Graph `includeInkML` still work in the stable API in 2026?
3. Exact Entra app-registration steps and whether personal-account sign-in needs a separate registration type.
4. Any free OSS parser for `.one` / `.onepkg` and its quality.

## Sources

- [C1] https://support.claude.com/en/articles/12542951-set-up-the-microsoft-365-connector
- [C2] https://code.claude.com/docs/en/mcp (sections "Use MCP servers from claude.ai", OAuth authentication)
- [G1] https://learn.microsoft.com/en-us/graph/onenote-get-content
- [G2] https://learn.microsoft.com/en-us/graph/onenote-input-output-html
- [G3] https://learn.microsoft.com/en-us/graph/onenote-get-content (resource `$value` section)
- [G4] https://learn.microsoft.com/en-us/archive/blogs/onenotedev/onenote-ink-beta-apis (archived 2017 blog, beta)
- [G5] https://learn.microsoft.com/en-us/graph/integrate-with-onenote (app-only removal note)
- [G6] https://learn.microsoft.com/en-us/graph/api/resources/onenote-api-overview
- [G7] https://learn.microsoft.com/en-us/graph/api/page-get?view=graph-rest-1.0 (permissions table)
- [G8] https://learn.microsoft.com/en-us/graph/onenote-error-codes
- [G9] https://learn.microsoft.com/en-us/graph/api/resources/onenote-api-overview (personal and organization accounts)
- [G10] https://learn.microsoft.com/en-us/graph/integrate-with-onenote (OCR statement)
- [W1] https://learn.microsoft.com/en-us/microsoft-365/copilot/extensibility/work-iq-api-overview (Work IQ scope, licensing)
- [W2] https://learn.microsoft.com/en-us/connectors/workiqmcp/
- [E1] https://support.microsoft.com/en-us/onenote/onenote-help-and-learning/export-notes-from-onenote-as-a-pdf
- [E2] https://support.microsoft.com/en-us/office/export-notes-as-a-pdf-in-onenote-for-the-web-a51d42d9-87f2-4797-81a7-cf8cb07ce61c
- [E3] https://support.microsoft.com/en-us/accessibility/onenote/use-a-screen-reader-to-share-and-collaborate-on-notebooks-in-onenote
- [E4] https://support.microsoft.com/en-us/office/export-notes-as-a-pdf-file-in-onenote-for-mac-a21723fb-6ac9-4c01-9462-e9edda15ab2d
- [S1] https://learn.microsoft.com/en-us/openspecs/office_file_formats/ms-one/73d22548-a613-4350-8c23-07d15576be50
- Secondary (community, not primary; used only where marked):
  [Q1] https://learn.microsoft.com/en-us/answers/questions/5813459/how-do-i-export-notebooks-from-onenote ;
  [Q2] https://learn.microsoft.com/en-ca/answers/questions/5903640/question-regarding-onenote-mcp
