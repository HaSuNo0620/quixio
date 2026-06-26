# Fastlane Build & Release Automation — Design

## Overview

Automate the full iOS build-to-submission pipeline for Fiveon using fastlane.
A single manual command covers: pod install → build number increment → archive → upload → (optionally) submit for review or push to TestFlight.
IAP product setup is also scripted as a one-time lane.

## Goals

- `bundle exec fastlane release` — build + upload + submit for App Store review
- `bundle exec fastlane beta` — build + upload to TestFlight (no review submission)
- `bundle exec fastlane setup_iap` — create Quixio_Pro IAP product (run once)
- Build number auto-increments on every run (no manual tracking)
- No 2FA required (App Store Connect API key authentication)

## Non-Goals

- Android build automation (iOS only)
- EAS Build (replaced by local Xcode build)
- Automated IAP screenshot upload (App Store Connect API does not support this)
- Automated metadata / screenshot management (skip_metadata: true)

## File Structure

```
my-quixio/
├── Gemfile                        # Locks fastlane gem version
├── Gemfile.lock                   # Generated, committed to git
├── fastlane/
│   ├── Appfile                    # Bundle ID, Team ID, Apple ID
│   ├── Fastfile                   # Lane definitions
│   └── api_key.json               # ASC API key — gitignored
└── .gitignore                     # Adds api_key.json, AuthKey_*.p8
```

## Authentication

App Store Connect API key (replaces Apple ID + 2FA):

- Created at: App Store Connect → Users and Access → Integrations → API Keys
- Role required: App Manager
- Files: `AuthKey_<KeyID>.p8` (private key) + Key ID + Issuer ID
- Stored as: `fastlane/api_key.json` (gitignored)

```json
{
  "key_id": "XXXXXXXXXX",
  "issuer_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "key_filepath": "fastlane/AuthKey_XXXXXXXXXX.p8",
  "in_house": false
}
```

## Lane: `beta`

Uploads a new build to TestFlight for internal testing.

```
1. pod install (from project root)
2. increment_build_number — reads CURRENT_PROJECT_VERSION from xcodeproj, +1
3. build_app (gym)
   - workspace: ios/Fiveon.xcworkspace
   - scheme: Fiveon
   - configuration: Release
   - export_method: app-store
4. upload_to_testflight
   - api_key_path: fastlane/api_key.json
   - skip_waiting_for_build_processing: true
```

## Lane: `release`

Builds, uploads, and submits for App Store review.

```
1-3. Same as beta
4. upload_to_app_store
   - api_key_path: fastlane/api_key.json
   - submit_for_review: true
   - automatic_release: false
   - skip_screenshots: true
   - skip_metadata: true
   - precheck_include_in_app_purchases: false
```

## Lane: `setup_iap`

Creates the Quixio_Pro IAP product via App Store Connect REST API. Run once per app.

```
1. Load API key from fastlane/api_key.json
2. GET /v1/apps?filter[bundleId]=com.yuuki.quixio → extract app ID
3. GET /v2/inAppPurchases?filter[app]=<appId> → check if Quixio_Pro exists
4. If not exists:
   POST /v2/inAppPurchases
   { productId: "Quixio_Pro", type: "NON_CONSUMABLE", name: "Pro" }
5. POST /v2/inAppPurchasePriceSchedules — set ¥120 (Tier 1)
6. POST /v2/inAppPurchaseLocalizations
   { locale: "ja", name: "Pro版", description: "広告を完全に削除します" }
⚠️  Screenshot must be added manually in App Store Connect
```

## Build Number Strategy

- fastlane `increment_build_number` reads `CURRENT_PROJECT_VERSION` from `ios/Fiveon.xcodeproj`
- Increments by 1 on each lane run
- `app.json` buildNumber is not updated (EAS is no longer used for production builds)

## Key Constants

| Item | Value |
|------|-------|
| Bundle ID | `com.yuuki.quixio` |
| Team ID | `GM8Q2249KG` |
| App Store App ID | `6782977597` |
| IAP Product ID | `Quixio_Pro` |
| IAP Type | Non-Consumable |
| IAP Price | ¥120 (Tier 1) |

## Security

- `fastlane/api_key.json` and `fastlane/AuthKey_*.p8` must never be committed to git
- Add both patterns to `.gitignore`
- `.env` already gitignored (Firebase / RevenueCat keys)

## Prerequisites (one-time setup)

1. `gem install bundler`
2. `bundle install` (installs fastlane)
3. Generate App Store Connect API key → save as `fastlane/api_key.json`
4. Run `bundle exec fastlane setup_iap` once to create the IAP product
5. Manually add IAP screenshot in App Store Connect
