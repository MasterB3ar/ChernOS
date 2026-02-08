# Releases / CI

## GitHub Actions build

The repo includes a workflow:

- `.github/workflows/build-iso.yml`

It runs on:
- `push`
- `workflow_dispatch`

and executes:

- `nix build .#iso -L --print-build-logs`

Then it uploads the ISO as a GitHub Actions artifact named:

- `chernos-os.iso`

## Suggested release flow

If you want downloadable ISOs on the Releases page (not just workflow artifacts), a typical approach is:

1. Create a Git tag for a version (e.g. `v2.0.0`).
2. Run the workflow (or have it trigger on tags).
3. Attach the built ISO to the GitHub Release.

This repo currently uploads only an Actions artifact; it does not publish to Releases automatically.
