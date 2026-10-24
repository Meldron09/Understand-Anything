# learn-anything

A Claude Code plugin that helps one learner understand any concept from any source, by interviewing them and producing a lesson in the format they want.

## Language

**Learner brief**:
The intake output: what the learner wants to understand and why, their probed current level, depth wanted, time budget, and mode. Downstream skills read it and need nothing else about the learner.
_Avoid_: profile, requirements

**Diagnostic ladder**:
The four short-answer questions intake asks in ascending difficulty (define, explain why, apply, edge case), each graded solid, shaky or missed, stopping at the first miss. Its graded answers are the learner brief's level evidence, and the comprehension check reuses its shape.
_Avoid_: placement test, self-assessment

**Core concept**:
A concept the learner brief names as essential for this learner's goal, chosen after the ladder and weighted toward the gaps it found. The comprehension check flags misses on these.
_Avoid_: key term, learning objective

**Source doc**:
The normalized text of one topic, URL, PDF, or OneNote page, where text exists, plus a pointer back to the original and an index of its chunks. A lesson has one source doc per source, never a merged one.
_Avoid_: input, raw source

**Mode**:
The output format the learner picks: text, slides, video, interactive HTML, quiz/flashcards, or a mix. A mode is a choice, not a skill.
_Avoid_: format, type

**Mode skill**:
The skill that produces one mode.

**Renderer**:
A library-specific way of producing video (for example Manim or Revideo), described in a reference file of the video mode skill. Not a skill and not a mode skill.
_Avoid_: video skill, engine

**Conductor**:
The one learner-facing skill. It runs in the main thread and sequences intake, ingest, the router, the mode skills and the comprehension check, holding only paths and unit statuses.
_Avoid_: orchestrator, entry skill

**Router**:
The step that turns the learner brief and the source doc's chunk index into the lesson plan. It never reads the full source text.

**Lesson plan**:
The router's output: a list of lesson units, each naming a mode, a source slice, and a renderer where relevant.

**Lesson artifact**:
The concrete output file a mode skill produces.
_Avoid_: deliverable, result

**Widget**:
One manipulable demo inside an interactive lesson artifact, with a short lead-in and a one-line takeaway. The interactive mode sizes a lesson unit by its widget count.
_Avoid_: exhibit, component

**Item**:
One question or card in a quiz or comprehension check, tagged with the core concept it tests and the ladder rung it sits on.
_Avoid_: question (too narrow, a flashcard is an item), card

**Scene**:
One idea of a video lesson unit, about 20 seconds long, with its own narration and its own silent clip. The video mode sizes a unit by its scene count.
_Avoid_: segment, slide, shot

**Storyboard**:
A video unit's scene list: for each scene, its one idea, its narration and a one-line visual intent. The one place the narration lives, so a different renderer can redraw a scene without re-authoring it.

**Comprehension check**:
The short closing diagnostic that follows any lesson, sized from the learner brief's depth and time budget and graded against its level. Not a mode and not a lesson artifact: the learner doesn't pick it, and it never appears in the lesson plan.
_Avoid_: test, exam, quiz (a quiz is a lesson artifact the learner chose)

**Handoff**:
The contract between the main thread and a subagent: a minimal self-contained brief in, a short summary plus a file path out.
_Avoid_: delegation payload

**Lesson unit**:
One entry in the lesson plan: a single mode applied to one or more source slices, possibly from different sources. The unit is the grain at which a lesson degrades.

**Chunk**:
A structure-bounded piece of one source, listed with a one-line summary in that source's chunk index. The smallest thing a slice can name.

**Slice**:
A contiguous run of chunks within one source, which a lesson unit teaches from. The router names slices from the chunk index without reading the source text.

**Dependency tier**:
A level of local tooling the learner's machine may or may not have (none, Python tooling, ffmpeg, or opt-in Node/Blender). A mode needs a tier; the plugin never assumes one.
_Avoid_: requirement level, prerequisite

**Preflight**:
The on-demand check of which dependency tiers and capabilities the learner's machine supports, run before any mode that needs them.
_Avoid_: health check, doctor

**Degradation**:
Replacing a lesson unit's mode with a lower-tier one when its tooling is missing or fails, ending at text. Always announced and recorded, never silent.
_Avoid_: fallback (that is a renderer's second choice, one rung of degradation)
