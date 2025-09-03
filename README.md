# rustore_connect plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-rustore_connect)

## Getting Started
This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-rustore_connect`, add it to your project by running:
```bash
fastlane add_plugin huawei_appgallery_connect
```

## About Fastlane Rustore Connect Plugin
**Fastlane plugin for publishing Android applications to RuStore.**
This plugin provides seamless integration with RuStore, allowing you to easily upload and manage your Android application releases directly from your CI/CD pipeline.

## Features

* Create new draft versions or reuse existing drafts
* Upload APK or AAB files
* Submit applications for review automatically
* Supports partial and delayed publication
* Handles draft strategies: DELETE, REUSE, FAIL

## Usage

```ruby
rustore_connect(
  key_id: "YOUR_KEY_ID",
  private_key: "YOUR_PRIVATE_KEY",
  package_name: "com.example.app",
  app_name: "My App",
  app_type: "GAMES",
  categories: "health, news",
  age_legal: "6+",
  short_description: "Brief app description",
  full_description: "Full app description",
  whats_new: "What's new in this version",
  moder_info: "Comment for moderator",
  price_value: "8799",
  seo_tag_ids: "tag1,tag2",
  publish_type: "INSTANTLY",
  publish_date_time: "2025-09-10T12:00:00+03:00",
  partial_value: "50",
  services_type: "Unknown",
  is_main_apk: true,
  apk_path: "./app-release.apk",
  is_aab: false,
  draft_strategy: "FAIL",
  submit_for_review: true
)
```

## Available Options

| Option              | Description                                         | Type    | Default     | Required |
| ------------------- | --------------------------------------------------- | ------- | ----------- | -------- |
| `key_id`            | Key ID for RuStore API                              | String  | —           | ✅        |
| `private_key`       | Private key for RuStore API                         | String  | —           | ✅        |
| `package_name`      | App package name (example: `com.example.app`)       | String  | —           | ✅        |
| `app_name`          | Application name                                    | String  | —           | ❌        |
| `app_type`          | Type of application (example: `GAMES`)              | String  | —           | ❌        |
| `categories`        | Version categories (example: `"health, news"`)      | String  | —           | ❌        |
| `age_legal`         | Age rating (example: `6+`)                          | String  | —           | ❌        |
| `short_description` | Brief description (max 80 chars)                    | String  | —           | ❌        |
| `full_description`  | Full description (max 4000 chars)                   | String  | —           | ❌        |
| `whats_new`         | What's new                                          | String  | —           | ❌        |
| `moder_info`        | Comment for moderator (max 180 chars)               | String  | —           | ❌        |
| `price_value`       | App price in kopecks (example: `8799`)              | String  | —           | ❌        |
| `seo_tag_ids`       | SEO tags                                            | String  | —           | ❌        |
| `publish_type`      | Publication type: `MANUAL`, `INSTANTLY`, `DELAYED`  | String  | `INSTANTLY` | ❌        |
| `publish_date_time` | Scheduled publication date (for delayed type)       | String  | —           | ❌        |
| `partial_value`     | Percentage for partial release                      | String  | —           | ❌        |
| `services_type`     | Service type: `HMS` or `Unknown`                    | String  | `Unknown`   | ❌        |
| `is_main_apk`       | Is main APK                                         | Boolean | `false`     | ❌        |
| `apk_path`          | Path to APK or AAB                                  | String  | —           | ✅        |
| `is_aab`            | Upload AAB instead of APK                           | Boolean | `false`     | ❌        |
| `draft_strategy`    | Strategy if draft exists: `DELETE`, `REUSE`, `FAIL` | String  | `FAIL`      | ❌        |
| `submit_for_review` | Should submit for review automatically              | Boolean | `true`      | ❌        |

## Draft Strategies

* `DELETE` – Delete existing draft and create a new one
* `REUSE` – Reuse the existing draft
* `FAIL` – Fail if a draft already exists

## Run tests for this plugin

To run both the tests, and code style validation, run

```
rake
```

To automatically fix many of the styling issues, use
```
rubocop -a
```

## Issues and Feedback
For any other issues and feedback about this plugin, please submit it to this repository.

## Troubleshooting
If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Using _fastlane_ Plugins
For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/).

## About _fastlane_
_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
