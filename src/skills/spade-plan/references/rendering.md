# Local Plan Rendering

Read this reference only after a Plan was written locally.
## Rendering and terminal link (v1.6+)

When a Plan is written locally (fallback-path, or — anticipating M-879's
hybrid mode — the local mirror path), invoke the SPADE renderer and
surface a clickable browser link:

1. Run `~/.spade/bin/spade-render <path-to-plan.md>` via {{SPADE_SHELL}}.
2. On success (exit 0), the renderer prints the absolute path of the
   rendered `.html` to stdout. Print a closing line to the human in
   the exact form:

   ```text
   View in browser: file://<absolute-path>.html
   ```

   Modern terminals (iTerm2, Warp, VS Code, Terminal.app) auto-linkify
   the `file://` URL for cmd-click.
3. On render failure with exit code 2 (pandoc not installed), print
   instead:

   ```text
   (HTML render unavailable: install pandoc — https://pandoc.org/installing.html — to enable. .md at <path>)
   ```

   Surface this hint on **every** Plan write until pandoc is
   installed (not one-time-per-session).
4. On any other render failure (exit 1 or 3), report the renderer's
   stderr and continue. Never abort the Plan flow on render
   failure — the `.md` file is the canonical artefact and must always
   succeed.

In the pure tracker-path (Linear-canonical, no local file written),
there is no markdown to render and no terminal link is emitted — but the
Terminal TL;DR above still fires, so the run is never left without a
closer.

The renderer's mechanism (Pandoc invocation, template, stylesheet,
CSP, palette) is documented once in `docs/FRAMEWORK.md` §HTML
Rendering. Do not re-specify it here.
