# Fastlane Build & Release Automation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add fastlane automation so that `bundle exec fastlane release` / `beta` / `setup_iap` cover the full build-to-submission pipeline with one command.

**Architecture:** Three fastlane lanes share a common `before_all` (pod install + build number increment). `beta` uploads to TestFlight; `release` uploads and submits for App Store review; `setup_iap` calls the App Store Connect REST API to create the Quixio_Pro non-consumable IAP product and Japanese localization.

**Tech Stack:** fastlane (Ruby), App Store Connect REST API v1/v2, Xcode 26.5, Expo SDK 54 / React Native 0.81.5

## Global Constraints

- Bundle ID: `com.yuuki.quixio`
- Team ID: `GM8Q2249KG`
- App Store App ID: `6782977597`
- IAP Product ID: `Quixio_Pro` (must match RevenueCat identifier exactly)
- IAP Type: Non-Consumable
- IAP Price: ¥120 (Tier 1, base territory: JPN)
- Workspace: `ios/Fiveon.xcworkspace`, Scheme: `Fiveon`
- `fastlane/api_key.json` must never be committed (already covered by `*.p8` in .gitignore; add json path separately)
- Do not modify `app.json` buildNumber — EAS is no longer used for production

---

## File Map

| Action | File |
|--------|------|
| Create | `Gemfile` |
| Create | `fastlane/Appfile` |
| Create | `fastlane/Fastfile` |
| Create | `fastlane/api_key.json.example` |
| Modify | `.gitignore` (add `fastlane/api_key.json`) |

---

### Task 1: Ruby environment — Gemfile + .gitignore

**Files:**
- Create: `Gemfile`
- Modify: `.gitignore`

**Interfaces:**
- Produces: `bundle exec fastlane lanes` command works without error

- [ ] **Step 1: Create Gemfile**

```ruby
# Gemfile
source "https://rubygems.org"

gem "fastlane"
```

- [ ] **Step 2: Install gems**

```bash
gem install bundler
bundle install
```

Expected: fastlane and dependencies install under `vendor/bundle` or system Ruby. No errors.

- [ ] **Step 3: Add fastlane/api_key.json to .gitignore**

Open `.gitignore` and add after the `# local env files` section:

```
# Fastlane secrets
fastlane/api_key.json
```

Note: `*.p8` is already in .gitignore so `AuthKey_*.p8` is already covered.

- [ ] **Step 4: Verify gitignore**

```bash
echo '{}' > fastlane/api_key.json
git status
```

Expected: `fastlane/api_key.json` does NOT appear in untracked files.

```bash
rm fastlane/api_key.json
```

- [ ] **Step 5: Commit**

```bash
git add Gemfile Gemfile.lock .gitignore
git commit -m "chore: add fastlane and update gitignore"
```

---

### Task 2: Fastlane config — Appfile + api_key template

**Files:**
- Create: `fastlane/Appfile`
- Create: `fastlane/api_key.json.example`

**Interfaces:**
- Produces: `app_identifier`, `team_id` available to all lanes

- [ ] **Step 1: Create fastlane/Appfile**

```ruby
# fastlane/Appfile
app_identifier "com.yuuki.quixio"
team_id "GM8Q2249KG"
```

- [ ] **Step 2: Create fastlane/api_key.json.example**

```json
{
  "key_id": "XXXXXXXXXX",
  "issuer_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "key_filepath": "fastlane/AuthKey_XXXXXXXXXX.p8",
  "in_house": false
}
```

- [ ] **Step 3: Document setup in example file comment**

The actual `api_key.json` is created by the user by:
1. App Store Connect → Users and Access → Integrations → API Keys → "+"
2. Role: App Manager
3. Download `.p8` file → save to `fastlane/AuthKey_<KeyID>.p8`
4. Copy `api_key.json.example` → `fastlane/api_key.json` and fill in values

- [ ] **Step 4: Verify Appfile is readable**

```bash
bundle exec fastlane run app_identifier
```

Expected: prints `com.yuuki.quixio`

- [ ] **Step 5: Commit**

```bash
git add fastlane/Appfile fastlane/api_key.json.example
git commit -m "chore: add fastlane Appfile and api_key template"
```

---

### Task 3: Beta lane — TestFlight upload

**Files:**
- Create: `fastlane/Fastfile`

**Interfaces:**
- Consumes: `fastlane/Appfile`, `fastlane/api_key.json` (user-created)
- Produces: `bundle exec fastlane beta` builds .ipa and uploads to TestFlight

- [ ] **Step 1: Create fastlane/Fastfile with beta lane**

```ruby
# fastlane/Fastfile
default_platform(:ios)

WORKSPACE  = "ios/Fiveon.xcworkspace"
SCHEME     = "Fiveon"
XCODEPROJ  = "ios/Fiveon.xcodeproj"
API_KEY    = "fastlane/api_key.json"
BUNDLE_ID  = "com.yuuki.quixio"
ASC_BASE   = "https://api.appstoreconnect.apple.com"

platform :ios do
  desc "Upload new build to TestFlight"
  lane :beta do
    sh("cd .. && pod install")
    increment_build_number(xcodeproj: XCODEPROJ)
    build_app(
      workspace: WORKSPACE,
      scheme: SCHEME,
      configuration: "Release",
      export_method: "app-store",
      output_directory: "build",
      output_name: "Fiveon.ipa"
    )
    upload_to_testflight(
      api_key_path: API_KEY,
      skip_waiting_for_build_processing: true
    )
  end
end
```

- [ ] **Step 2: Verify lanes are recognized**

```bash
bundle exec fastlane lanes
```

Expected output includes:
```
-----| ios |-----
lane :beta
  Upload new build to TestFlight
```

- [ ] **Step 3: Dry-run syntax check**

```bash
bundle exec fastlane beta --env test 2>&1 | head -5
```

Expected: starts without Ruby syntax errors (will fail on missing api_key.json — that's expected at this stage).

- [ ] **Step 4: Commit**

```bash
git add fastlane/Fastfile
git commit -m "feat(fastlane): add beta lane for TestFlight upload"
```

---

### Task 4: Release lane — App Store submission

**Files:**
- Modify: `fastlane/Fastfile` (add `release` lane inside `platform :ios do`)

**Interfaces:**
- Consumes: same as Task 3
- Produces: `bundle exec fastlane release` builds, uploads, and submits for review

- [ ] **Step 1: Add release lane to Fastfile**

Inside `platform :ios do`, after the `beta` lane, add:

```ruby
  desc "Build and submit to App Store for review"
  lane :release do
    sh("cd .. && pod install")
    increment_build_number(xcodeproj: XCODEPROJ)
    build_app(
      workspace: WORKSPACE,
      scheme: SCHEME,
      configuration: "Release",
      export_method: "app-store",
      output_directory: "build",
      output_name: "Fiveon.ipa"
    )
    upload_to_app_store(
      api_key_path: API_KEY,
      submit_for_review: true,
      automatic_release: false,
      skip_screenshots: true,
      skip_metadata: true,
      precheck_include_in_app_purchases: false
    )
  end
```

- [ ] **Step 2: Verify both lanes are listed**

```bash
bundle exec fastlane lanes
```

Expected: both `beta` and `release` appear.

- [ ] **Step 3: Commit**

```bash
git add fastlane/Fastfile
git commit -m "feat(fastlane): add release lane for App Store submission"
```

---

### Task 5: setup_iap lane — App Store Connect IAP creation

**Files:**
- Modify: `fastlane/Fastfile` (add helpers + `setup_iap` lane)

**Interfaces:**
- Consumes: `fastlane/api_key.json`, `fastlane/AuthKey_*.p8`
- Produces: `bundle exec fastlane setup_iap` creates Quixio_Pro IAP with Japanese localization

**Note on pricing:** Setting the price schedule requires looking up a price point ID from ASC. This lane sets the price to ¥120 by finding the matching price point in the JPN territory and posting a price schedule. If the price point lookup fails, the IAP is still created — set the price manually in App Store Connect.

- [ ] **Step 1: Add HTTP helpers and setup_iap lane to Fastfile**

After the `end` that closes `platform :ios do`, and before the final `end` of the file, add these helpers. Then add the `setup_iap` lane inside `platform :ios do`.

Full updated `fastlane/Fastfile`:

```ruby
# fastlane/Fastfile
require 'net/http'
require 'json'
require 'openssl'
require 'jwt'

default_platform(:ios)

WORKSPACE  = "ios/Fiveon.xcworkspace"
SCHEME     = "Fiveon"
XCODEPROJ  = "ios/Fiveon.xcodeproj"
API_KEY    = "fastlane/api_key.json"
BUNDLE_ID  = "com.yuuki.quixio"
ASC_BASE   = "https://api.appstoreconnect.apple.com"

platform :ios do
  desc "Upload new build to TestFlight"
  lane :beta do
    sh("cd .. && pod install")
    increment_build_number(xcodeproj: XCODEPROJ)
    build_app(
      workspace: WORKSPACE,
      scheme: SCHEME,
      configuration: "Release",
      export_method: "app-store",
      output_directory: "build",
      output_name: "Fiveon.ipa"
    )
    upload_to_testflight(
      api_key_path: API_KEY,
      skip_waiting_for_build_processing: true
    )
  end

  desc "Build and submit to App Store for review"
  lane :release do
    sh("cd .. && pod install")
    increment_build_number(xcodeproj: XCODEPROJ)
    build_app(
      workspace: WORKSPACE,
      scheme: SCHEME,
      configuration: "Release",
      export_method: "app-store",
      output_directory: "build",
      output_name: "Fiveon.ipa"
    )
    upload_to_app_store(
      api_key_path: API_KEY,
      submit_for_review: true,
      automatic_release: false,
      skip_screenshots: true,
      skip_metadata: true,
      precheck_include_in_app_purchases: false
    )
  end

  desc "Create Quixio_Pro IAP in App Store Connect (run once)"
  lane :setup_iap do
    key_data   = JSON.parse(File.read(API_KEY))
    asc_token  = asc_jwt(key_data)
    headers    = asc_headers(asc_token)

    # 1. Get app ID
    apps = asc_get("#{ASC_BASE}/v1/apps?filter[bundleId]=#{BUNDLE_ID}", headers)
    app_id = apps["data"][0]["id"]
    UI.message("App ID: #{app_id}")

    # 2. Check if IAP already exists
    existing = asc_get(
      "#{ASC_BASE}/v2/inAppPurchases?filter[app]=#{app_id}&filter[productId]=Quixio_Pro",
      headers
    )["data"]

    if existing.length > 0
      iap_id = existing[0]["id"]
      UI.success("Quixio_Pro already exists (#{iap_id}), skipping creation")
    else
      # 3. Create IAP
      result = asc_post("#{ASC_BASE}/v2/inAppPurchases", headers, {
        data: {
          type: "inAppPurchases",
          attributes: {
            name: "Pro",
            productId: "Quixio_Pro",
            inAppPurchaseType: "NON_CONSUMABLE"
          },
          relationships: {
            app: { data: { type: "apps", id: app_id } }
          }
        }
      })
      iap_id = result["data"]["id"]
      UI.success("Created IAP: #{iap_id}")
    end

    # 4. Add Japanese localization (idempotent — re-posting is harmless)
    asc_post("#{ASC_BASE}/v2/inAppPurchaseLocalizations", headers, {
      data: {
        type: "inAppPurchaseLocalizations",
        attributes: { locale: "ja", name: "Pro版", description: "広告を完全に削除します" },
        relationships: {
          inAppPurchaseV2: { data: { type: "inAppPurchases", id: iap_id } }
        }
      }
    })
    UI.success("Japanese localization set")

    # 5. Set price: ¥120 (Tier 1, JPN territory)
    price_points = asc_get(
      "#{ASC_BASE}/v2/inAppPurchases/#{iap_id}/pricePoints?filter[territory]=JPN&limit=200",
      headers
    )["data"]
    tier1 = price_points.find { |pp| pp["attributes"]["customerPrice"] == "120" }

    if tier1.nil?
      UI.important("⚠️  Could not find ¥120 price point. Set price manually in App Store Connect.")
    else
      asc_post("#{ASC_BASE}/v2/inAppPurchasePriceSchedules", headers, {
        data: {
          type: "inAppPurchasePriceSchedules",
          relationships: {
            inAppPurchase:  { data: { type: "inAppPurchases", id: iap_id } },
            baseTerritory:  { data: { type: "territories", id: "JPN" } },
            manualPrices: {
              data: [{ type: "inAppPurchasePrices", id: "price-jpn" }]
            }
          }
        },
        included: [{
          type: "inAppPurchasePrices",
          id: "price-jpn",
          attributes: { startDate: nil },
          relationships: {
            inAppPurchaseV2:        { data: { type: "inAppPurchases",           id: iap_id       } },
            inAppPurchasePricePoint: { data: { type: "inAppPurchasePricePoints", id: tier1["id"] } }
          }
        }]
      })
      UI.success("Price set to ¥120 (JPN Tier 1)")
    end

    UI.important("⚠️  Add a screenshot in App Store Connect → Fiveon → In-App Purchases → Quixio_Pro before submitting for review.")
  end
end

# ---- ASC API helpers ----

def asc_jwt(key_data)
  private_key = OpenSSL::PKey::EC.new(File.read(key_data["key_filepath"]))
  now = Time.now.to_i
  JWT.encode(
    { iss: key_data["issuer_id"], iat: now, exp: now + 1200, aud: "appstoreconnect-v1" },
    private_key,
    "ES256",
    { kid: key_data["key_id"] }
  )
end

def asc_headers(token)
  { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" }
end

def asc_get(url, headers)
  uri = URI(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  req = Net::HTTP::Get.new(uri)
  headers.each { |k, v| req[k] = v }
  JSON.parse(http.request(req).body)
end

def asc_post(url, headers, body)
  uri = URI(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  req = Net::HTTP::Post.new(uri)
  headers.each { |k, v| req[k] = v }
  req.body = body.to_json
  JSON.parse(http.request(req).body)
end
```

- [ ] **Step 2: Verify all three lanes are listed**

```bash
bundle exec fastlane lanes
```

Expected:
```
lane :beta       Upload new build to TestFlight
lane :release    Build and submit to App Store for review
lane :setup_iap  Create Quixio_Pro IAP in App Store Connect (run once)
```

- [ ] **Step 3: Commit**

```bash
git add fastlane/Fastfile
git commit -m "feat(fastlane): add setup_iap lane with ASC REST API"
```

---

## Post-Setup Checklist (manual, one-time)

After all tasks are implemented:

1. Generate App Store Connect API key (App Manager role)
2. Save `.p8` to `fastlane/AuthKey_<KeyID>.p8`
3. Copy `fastlane/api_key.json.example` → `fastlane/api_key.json` and fill values
4. Run `bundle exec fastlane setup_iap` to create IAP
5. Add IAP screenshot manually in App Store Connect
6. Run `bundle exec fastlane beta` for a TestFlight build
7. Run `bundle exec fastlane release` to submit for review
