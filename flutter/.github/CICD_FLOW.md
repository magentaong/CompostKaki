# CI/CD Flow Diagram

## Complete Pipeline Visualization

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         DEVELOPER WORKFLOW                               │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    │                               │
            ┌───────▼────────┐            ┌────────▼────────┐
            │  Feature Dev   │            │   Bug Fix Dev   │
            │  (feature/*)   │            │   (fix/*)       │
            └───────┬────────┘            └────────┬────────┘
                    │                              │
                    └──────────┬───────────────────┘
                               │
                      ┌────────▼────────┐
                      │  Create Pull    │
                      │    Request      │
                      └────────┬────────┘
                               │
┌──────────────────────────────┴───────────────────────────────┐
│                     GITHUB ACTIONS TRIGGERED                 │
└──────────────────────────────────────────────────────────────┘
                               │
                ┌──────────────┼──────────────┐
                │              │              │
        ┌───────▼──────┐ ┌────▼─────┐ ┌─────▼──────┐
        │   Format     │ │ Analyze  │ │   Linter   │
        │    Check     │ │  (dart)  │ │  (60+ rules)│
        └───────┬──────┘ └────┬─────┘ └─────┬──────┘
                │              │              │
                └──────────────┼──────────────┘
                               │
                       ✅ Pass │ ❌ Fail → Stop & Notify
                               │
                ┌──────────────▼──────────────┐
                │      UNIT TESTS (Stage 2)   │
                ├─────────────────────────────┤
                │ • Run all tests             │
                │ • Generate coverage         │
                │ • Upload to Codecov         │
                └──────────────┬──────────────┘
                               │
                       ✅ Pass │ ❌ Fail → Stop & Notify
                               │
                ┌──────────────▼──────────────┐
                │   BUILD APK/IPA (Stage 3)   │
                ├─────────────────────────────┤
                │ • Android Debug APK         │
                │ • Android Release APK       │
                │ • iOS Release Build         │
                └──────────────┬──────────────┘
                               │
                       ✅ Pass │ ❌ Fail → Stop & Notify
                               │
                ┌──────────────▼──────────────┐
                │ INTEGRATION TESTS (Stage 4) │
                ├─────────────────────────────┤
                │ • Start emulator            │
                │ • Run E2E tests             │
                │ • Validate user flows       │
                └──────────────┬──────────────┘
                               │
                       ✅ Pass │ ❌ Fail → Stop & Notify
                               │
                ┌──────────────▼──────────────┐
                │      ARTIFACTS STORED       │
                ├─────────────────────────────┤
                │ • APKs (30-90 days)         │
                │ • Coverage reports          │
                │ • Test results              │
                └──────────────┬──────────────┘
                               │
                     ┌─────────┴─────────┐
                     │ Branch = develop? │
                     └─────────┬─────────┘
                               │
                    Yes ┌──────┴──────┐ No
                        │             │
               ┌────────▼────────┐    │
               │    FIREBASE     │    │
               │  APP DISTRO     │    │
               ├─────────────────┤    │
               │ • Build APK     │    │
               │ • Upload        │    │
               │ • Notify testers│    │
               └────────┬────────┘    │
                        │             │
                        └──────┬──────┘
                               │
                    ┌──────────▼──────────┐
                    │  MANUAL REVIEW      │
                    │  (Code Review)      │
                    └──────────┬──────────┘
                               │
                       ┌───────┴────────┐
                       │  Approved?     │
                       └───────┬────────┘
                               │
                    Yes ┌──────┴──────┐ No → Request Changes
                        │             │
                ┌───────▼────────┐    │
                │  MERGE TO MAIN │    │
                └───────┬────────┘    │
                        │             │
                        └──────┬──────┘
                               │
                ┌──────────────▼──────────────┐
                │   PRODUCTION RELEASE        │
                ├─────────────────────────────┤
                │ • Tag version               │
                │ • Build release artifacts   │
                │ • Deploy to stores          │
                └─────────────────────────────┘
```

## Parallel Workflow: Firebase Distribution

```
┌─────────────────────────────────────────────────────────┐
│             FIREBASE DISTRIBUTION WORKFLOW              │
│                  (develop branch only)                  │
└─────────────────────────────────────────────────────────┘
                            │
                ┌───────────▼───────────┐
                │ Push to develop branch│
                └───────────┬───────────┘
                            │
                ┌───────────▼───────────┐
                │  Run Tests            │
                └───────────┬───────────┘
                            │
                ┌───────────▼───────────┐
                │  Build APK            │
                └───────────┬───────────┘
                            │
                ┌───────────▼───────────┐
                │  Upload to Firebase   │
                │  App Distribution     │
                └───────────┬───────────┘
                            │
                ┌───────────▼───────────┐
                │  Generate Release     │
                │  Notes (from commit)  │
                └───────────┬───────────┘
                            │
                ┌───────────▼───────────┐
                │  Notify Testers       │
                │  (via Firebase)       │
                └───────────────────────┘
```

## Test Execution Flow

```
┌────────────────────────────────────────────────┐
│              TEST EXECUTION FLOW               │
└────────────────────────────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
  ┌─────▼─────┐ ┌──────▼──────┐ ┌────▼────┐
  │   Unit    │ │   Widget    │ │ Service │
  │   Tests   │ │   Tests     │ │  Tests  │
  └─────┬─────┘ └──────┬──────┘ └────┬────┘
        │              │              │
        └──────────────┼──────────────┘
                       │
            ┌──────────▼──────────┐
            │  Coverage Report    │
            │  (lcov.info)        │
            └──────────┬──────────┘
                       │
            ┌──────────▼──────────┐
            │  Upload to Codecov  │
            │  (optional)         │
            └──────────┬──────────┘
                       │
            ┌──────────▼──────────┐
            │  Integration Tests  │
            │  (E2E flows)        │
            └──────────┬──────────┘
                       │
                  ✅ All Pass
```

## Status Checks Required

```
┌────────────────────────────────────────────────┐
│         BRANCH PROTECTION STATUS CHECKS        │
├────────────────────────────────────────────────┤
│                                                │
│  ✅ flutter-format                             │
│  ✅ flutter-analyze                            │
│  ✅ unit-tests                                 │
│  ✅ build-android                              │
│  ✅ build-ios (optional)                       │
│  ✅ integration-tests                          │
│  ✅ code-review-approval (1+ reviewer)         │
│                                                │
└────────────────────────────────────────────────┘
          │
          ▼
    All checks pass → Merge enabled
    Any check fails → Merge blocked
```

## Local Development Cycle

```
┌─────────────────────────────────────────────────┐
│          LOCAL DEVELOPMENT WORKFLOW             │
└─────────────────────────────────────────────────┘
                       │
          ┌────────────▼────────────┐
          │  Write Code / Features  │
          └────────────┬────────────┘
                       │
          ┌────────────▼────────────┐
          │  flutter format lib/    │
          └────────────┬────────────┘
                       │
          ┌────────────▼────────────┐
          │  flutter analyze        │
          └────────────┬────────────┘
                       │
          ┌────────────▼────────────┐
          │  flutter test           │
          └────────────┬────────────┘
                       │
               ✅ All Pass?
                       │
              Yes      │      No
                       │       └─→ Fix Issues
          ┌────────────▼────────────┐
          │  git add & commit       │
          └────────────┬────────────┘
                       │
          ┌────────────▼────────────┐
          │  Pre-commit hooks run   │
          │  (format, analyze)      │
          └────────────┬────────────┘
                       │
               ✅ Pass?
                       │
              Yes      │      No
                       │       └─→ Auto-fix or reject
          ┌────────────▼────────────┐
          │  git push origin        │
          └────────────┬────────────┘
                       │
          ┌────────────▼────────────┐
          │  CI/CD Pipeline Starts  │
          └─────────────────────────┘
```

## Artifact Storage & Retention

```
┌──────────────────────────────────────────┐
│         ARTIFACT MANAGEMENT              │
├──────────────────────────────────────────┤
│                                          │
│  app-debug.apk         → 30 days        │
│  app-release-*.apk     → 90 days        │
│  app-ios.ipa           → 90 days        │
│  coverage/lcov.info    → 30 days        │
│  test-results.xml      → 30 days        │
│                                          │
└──────────────────────────────────────────┘
        │
        └─→ Downloadable from GitHub Actions
```

## Deployment Strategies

```
┌─────────────────────────────────────────────────────┐
│                 DEPLOYMENT FLOW                     │
└─────────────────────────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
   ┌────▼────┐     ┌─────▼──────┐   ┌────▼────┐
   │ Firebase│     │Google Play │   │TestFlight│
   │App Dist │     │  (Android) │   │  (iOS)   │
   └────┬────┘     └─────┬──────┘   └────┬────┘
        │                │                │
  ┌─────▼─────┐    ┌─────▼──────┐   ┌────▼─────┐
  │Beta       │    │Internal    │   │Beta      │
  │Testers    │    │Testing     │   │Testers   │
  └─────┬─────┘    └─────┬──────┘   └────┬─────┘
        │                │                │
        └────────────────┼────────────────┘
                         │
                    ┌────▼────┐
                    │Production│
                    │ Release  │
                    └──────────┘
```

---

## Key Metrics

### Build Times (Approximate)
- ⚡ Format Check: 30 seconds
- ⚡ Static Analysis: 1 minute
- ⚡ Unit Tests: 2-3 minutes
- ⚡ Android Build: 5-7 minutes
- ⚡ iOS Build: 8-10 minutes
- ⚡ Integration Tests: 5-10 minutes

**Total Pipeline Time**: 15-25 minutes

### Success Criteria
- ✅ 100% of tests passing
- ✅ 0 linter errors
- ✅ 0 formatting issues
- ✅ Code coverage > 80% (target)
- ✅ Build successful on all platforms
- ✅ 1+ reviewer approval

---

This visualization helps understand the complete flow from development to production!

