# ai-coding-tools

This Nix flake includes:

- @anthropic-ai/claude-code npm package as `claude` nix package
- @github/copilot npm package as `copilot` nix package
- @sourcegraph/amp npm package as `amp` nix package

### Install

One of these packages, for example `claude`:

```
$ nix profile install github:olebedev/ai-coding-tools#claude
```

Or you can install all packages:

```
$ nix profile install github:olebedev/ai-coding-tools
```
