# Werf Integration

This guide explains how to use the ks-universal chart with [werf](https://werf.io) for CI/CD.

## Overview

The chart provides native support for Werf through:
- Special values export
- Dynamic image tag management
- Multi-image support
- Integration with Werf's CI/CD pipeline

## Setup

### 1. Chart Dependencies

Add ks-universal as a dependency in your `Chart.yaml`:

```yaml
apiVersion: v2
dependencies:
  - name: ks-universal
    version: "v0.2.9"
    repository: https://wowsel.github.io/ks-universal-chart
    export-values:
      - parent: werf
        child: werf
```
Next, pull dependencies.
```bash
cd .helm
werf helm dependency update
```

### 2. Werf Configuration

Create or update your `werf.yaml`:

```yaml
project: my-project
configVersion: 1
image: app
  dockerfile: Dockerfile
---
image: worker
  dockerfile: Dockerfile.worker
```

### 3. Values Configuration

Configure your `values.yaml` to use Werf image references:

```yaml
deployments:
  app:
    containers:
      main:
        image: "{{ $.Values.werf.repo }}"
        imageTag: "{{ $.Values.werf.tag.app }}"

  worker:
    containers:
      main:
        image: "{{ $.Values.werf.repo }}"
        imageTag: "{{ $.Values.werf.tag.worker }}"
```

## Usage Examples

#### Be careful when using ks-universal as a dependency - you must specify all parameters in values ​​under `ks-universal` key.

### Single Image Application

```yaml
# werf.yaml
project: simple-app
configVersion: 1
image: app
  dockerfile: Dockerfile

# values.yaml
ks-universal:
  deployments:
    web:
      containers:
        main:
          image: "{{ $.Values.werf.repo }}"
          imageTag: "{{ $.Values.werf.tag.app }}"
```
