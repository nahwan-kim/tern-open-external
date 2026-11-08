# Open External for Tern

A [Tern](https://stencil.so/tern) plugin: ⌘⌥-click a file link in an agent's transcript (omp's file and
`폴더 열기` links) to open it outside Tern.

| Click | Opens |
| --- | --- |
| ⌘⌥ on a folder link | the folder in QSpace Pro |
| ⌘⌥ on a file link | the file in its default app; a type no app claims (`.luau`) in the default text editor |
| ⌘ on any link | Tern's own handling, unchanged (a file block beside the pane) |

A missing path shows a "파일을 찾지 못했어요" toast. A trailing `:LINE[:COL]` that names no file is dropped.

## Install

```sh
tern plugin install github.com/nahwan-kim/tern-open-external
# or, from a clone: tern plugin link .
```

To use Finder or another app for folders, change `FOLDER_APP` at the top of `window.luau` and run
`tern plugin reload open-external`.

## Limits

- **Why not ⌘⇧:** Tern's ⇧-click extends the text selection on mouse-down, before any plugin sees the click, and
  plugins cannot clear that selection. ⌥ is Tern's own link modifier, so ⌘⌥ takes over Tern's "⌥: open beside" for
  file links.
- **Agent transcripts only:** links in omp surfaces reach `tern.route.link` with the modifiers. In a plain terminal
  grid, a simulated ⌘⌥-click on an OSC 8 link did not reach the route.
- **Bare paths:** paths Tern detects in output by itself arrive at `route.open` without the modifiers, so they keep
  Tern's handling.
- **Remote panes:** links in panes on a remote host name that host's files, so they keep Tern's handling.
- macOS only (`open`).

## License

MIT
