# Local Scope Rendering

Read this reference only after a local Scope file was written.
## Closing Step — Render and Link (MANDATORY)

This is the **mandatory final step** of every `/spade-scope` run that
writes a local Scope file — not an optional appendix. It runs **after**
the Terminal TL;DR (§ Closing Step — Terminal TL;DR), which is itself
mandatory in every mode; in `linear` mode, where nothing is rendered,
the TL;DR is the final step instead. The skill run is not complete until
the human has been shown the closing line below (the `file://…` link, or
the pandoc hint). Reaching the end of the Linear integration is not the
end of the skill.

After writing a local Scope file to `.spade/scopes/<slug>.md`
(modes `local` and `hybrid` per M-879 — skip in `linear` mode where
no local file is written), invoke the SPADE renderer and surface a
clickable browser link:

1. Run `~/.spade/bin/spade-render <path-to-scope.md>` via {{SPADE_SHELL}}.
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

   Surface this hint on **every** Scope write until pandoc is
   installed (not one-time-per-session).
4. On any other render failure (exit 1 or 3), report the renderer's
   stderr and continue. Never abort the Scope flow on render
   failure — the `.md` file is the canonical artefact and must always
   succeed.

The renderer's mechanism (Pandoc invocation, template, stylesheet,
CSP, palette) is documented once in `docs/FRAMEWORK.md` §HTML
Rendering. Do not re-specify it here.
