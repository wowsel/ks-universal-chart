# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.22] - 2026-01-27

### Added
- Global labels and annotations support via `generic.labels` and `generic.annotations`
- Labels and annotations are applied to all resources: Deployments, Jobs, CronJobs, Services, Ingresses, ConfigMaps, Secrets, Certificates, ServiceAccounts, ServiceMonitors, HPAs, PDBs, PVCs, and DexAuthenticators
- For Deployments, Jobs, and CronJobs, global labels/annotations are also applied to Pod templates
- Support for `deploymentsGeneral.labels` and `deploymentsGeneral.annotations` with correct merge priority
- New test file `global_labels_test.yaml` for testing global labels functionality

### Changed
- Merge priority for labels/annotations: `generic` (lowest) → `deploymentsGeneral` → resource-specific (highest)

## [0.2.21] - Previous

### Added
- Custom `serviceAccountName` support globally and per-resource
- Fix for cert-manager annotations in Ingress when autoCreateCertificate is enabled
- `priorityClassName` support for Deployments, CronJobs and Jobs
