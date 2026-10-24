# Changelog

## [1.1.2](https://github.com/Olensys/terraform-google-gke-cluster/compare/v1.1.1...v1.1.2) (2026-10-24)


### Bug Fixes

* **examples:** unique application slug so concurrent integration runs do not collide ([#3](https://github.com/Olensys/terraform-google-gke-cluster/issues/3)) ([41725f3](https://github.com/Olensys/terraform-google-gke-cluster/commit/41725f34ac9c2c33234683fa0bcaa116dc7aa2d1))

## [1.1.1](https://github.com/Olensys/terraform-google-gke-cluster/compare/v1.1.0...v1.1.1) (2026-10-24)


### Bug Fixes

* **examples:** use the smallest shapes for the integration apply ([998920e](https://github.com/Olensys/terraform-google-gke-cluster/commit/998920ef279223640d2cc793d8072f4540ebde07))
* run integration on change and weekly instead of nightly ([4f83622](https://github.com/Olensys/terraform-google-gke-cluster/commit/4f83622b0859996e586da7d344a6f374e5bb5129))

## 1.1.0

### Fixes

- normalise `context.extra_tags` keys and values to valid GCP label syntax (lowercase, `[^a-z0-9_-]` replaced by `-`, 63 characters); `labels` are applied verbatim and win

### Tests

- `test_tags_contract` now covers mixed-case extra tags and verifies normalisation

### Docs

- Usage shows the naming module; Opinions describe label normalisation

### Behaviour changes

- `labels` output and applied labels now contain normalised keys and values for `context.extra_tags` (for example `Team = "Core Team"` becomes `team = "core-team"`). Callers that relied on mixed-case or space-containing extra tags must expect the normalised form; values passed in `labels` are unchanged.

## 1.0.0

- Private GKE cluster wrapper over terraform-google-modules/kubernetes-engine 46.0.0 (private-cluster) with Workload Identity, shielded nodes, Dataplane V2, release channel, maintenance window and node pools from a map.
