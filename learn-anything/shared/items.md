# Items

Single source of truth for an item, read by the quiz skill (quiz units and the comprehension check). `items.json` is one JSON array of objects, written with the `Write` tool and nothing else in the file.

| Field | Meaning |
|---|---|
| `id` | `i01`... unique within the file |
| `type` | `mcq` (auto-checked) · `short` (type an answer, reveal, self-rate) · `flip` (flashcard, self-rated) · `explain` (check only, mastery depth) |
| `concept` | the exact `core:` name from `brief.md`, or `other` |
| `rung` | `define` · `why` · `apply` · `edge` |
| `q` | the question or card front |
| `answer` | the reference answer or card back |
| `rubric` | what a `solid` answer contains, one or two lines (used for grading); required in the check, optional in a quiz |
| `choices` | `mcq` only: at least two `{"text": "...", "correct": true}` objects, exactly one with `correct`, `correct` omitted on the others |
| `alt` | a fresh variant of the item testing the same thing (serves the check's one re-ask); required in the check, omit in a quiz |
| `slice` | the slice the item draws from, e.g. `s2#c03` |

Rules:

- Items sit in rung order within a concept; all text is plain text, never HTML.
- The array is embedded in an HTML `<script>`: write `<` as `<` inside every string.
- Grades vocabulary everywhere: `solid | shaky | missed`.
