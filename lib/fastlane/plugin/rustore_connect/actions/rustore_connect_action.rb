require 'fastlane/action'
require_relative '../helper/rustore_connect_helper'
require_relative '../lib/rustore_connect_draft_strategy'

module Fastlane
  module Actions
    class RustoreConnectAction < Action
      def self.run(params)
        token = Helper::RustoreConnectHelper.get_token(params[:key_id], params[:private_key])

        if token.nil?
          UI.message("Cannot retrieve token, please check your Key ID and private key")
        else
          version_id = Helper::RustoreConnectHelper.get_app_versions(
            token,
            params[:package_name],
            version_statuses: 'DRAFT'
          )

          UI.message("Debug: version_id before strategy check: #{version_id}")
          UI.message("Debug: strategy check: #{params[:draft_strategy]}")

          if version_id.nil?
            # No draft exists → create a new one
            UI.message("No existing draft found. Creating a new draft...")
            version_id = Helper::RustoreConnectHelper.create_draft(
              token,
              params[:package_name],
              params[:app_name],
              params[:app_type],
              params[:categories],
              params[:age_legal],
              params[:short_description],
              params[:full_description],
              params[:whats_new],
              params[:moder_info],
              params[:price_value],
              params[:seo_tag_ids],
              params[:publish_type],
              params[:publish_date_time],
              params[:partial_value]
            )

          else
            # Draft exists → handle based on draft_strategy
            case params[:draft_strategy]
            when RustoreConnectDraftStrategy::DELETE
              UI.message("Draft exists (ID=#{version_id}). Deleting and creating a new one...")

              Helper::RustoreConnectHelper.delete_draft(
                token,
                params[:package_name],
                version_id
              )

              version_id = Helper::RustoreConnectHelper.create_draft(
                token,
                params[:package_name],
                params[:app_name],
                params[:app_type],
                params[:categories],
                params[:age_legal],
                params[:short_description],
                params[:full_description],
                params[:whats_new],
                params[:moder_info],
                params[:price_value],
                params[:seo_tag_ids],
                params[:publish_type],
                params[:publish_date_time],
                params[:partial_value]
              )

            when RustoreConnectDraftStrategy::REUSE
              UI.message("Draft exists (ID=#{version_id}). Reusing existing draft.")

            when RustoreConnectDraftStrategy::FAIL
              UI.user_error!("Draft already exists (ID=#{version_id}) and draft_strategy is set to 'FAIL'")

            else
              UI.user_error!("Unknown draft_strategy: #{params[:draft_strategy]}. Allowed values: delete_and_create, reuse_existing, fail_if_exists")
            end
          end

          UI.message("Using version_id=#{version_id} for upload...")

          # Upload APK or AAB file
          Helper::RustoreConnectHelper.upload(token, params[:package_name], version_id, params[:is_aab], params[:apk_path], params[:services_type], params[:is_main_apk])

          if params[:submit_for_review] === true
            Helper::RustoreConnectHelper::commit_version(token, params[:package_name], version_id)
          end

        end
      end

      def self.description
        "Fastlane plugin for publishing Android applications to RuStore."
      end

      def self.authors
        ["Mikhail Matsera"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "This Fastlane plugin provides seamless integration with RuStore, allowing you to easily upload and manage your Android application releases directly from your CI/CD pipeline."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :key_id,
                                       env_name: "RUSTORE_CONNECT_KEY_ID",
                                       description: "Key id",
                                       optional: false,
                                       type: String,
                                       ),

          FastlaneCore::ConfigItem.new(key: :private_key,
                                       env_name: "RUSTORE_CONNECT_PRIVATE_KEY",
                                       description: "Private key",
                                       optional: false,
                                       type: String,
                                       ),

          FastlaneCore::ConfigItem.new(key: :package_name,
                                       env_name: "RUSTORE_CONNECT_PACKAGE_NAME",
                                       description: "Наименование пакета приложения (example: `com.example.example`)",
                                       optional: false,
                                       type: String,
                                       ),

          FastlaneCore::ConfigItem.new(key: :app_name,
                                       env_name: "RUSTORE_CONNECT_APP_NAME",
                                       description: "App name (example `My App`)",
                                       optional: true,
                                       type: String,
                                       ),

          FastlaneCore::ConfigItem.new(key: :app_type,
                                       env_name: "RUSTORE_CONNECT_APP_TYPE",
                                       description: "Тип приложения (example `GAMES`)",
                                       optional: true,
                                       type: String,
                                       ),

          FastlaneCore::ConfigItem.new(key: :categories,
                                       env_name: "RUSTORE_CONNECT_CATEGORIES",
                                       description: "Категории версии. (example `\"health\", \"news\"`)",
                                       optional: true,
                                       type: String,
                                       ),

          FastlaneCore::ConfigItem.new(key: :age_legal,
                                       env_name: "RUSTORE_CONNECT_AGE_LEGAL",
                                       description: "Возрастная категория. (example `6+`)",
                                       optional: true,
                                       type: String,
                                       ),

          FastlaneCore::ConfigItem.new(key: :short_description,
                                       env_name: "RUSTORE_CONNECT_SHORT_DESCRIPTION",
                                       description: "Brief app release description. Maximum length: 80 characters",
                                       optional: true,
                                       type: String,
                                       ),

          FastlaneCore::ConfigItem.new(key: :full_description,
                                       env_name: "RUSTORE_CONNECT_FULL_DESCRIPTION",
                                       description: "Full description. Maximum length: 4000 characters",
                                       optional: true,
                                       type: String,
                                       ),

          FastlaneCore::ConfigItem.new(key: :whats_new,
                                       env_name: "RUSTORE_CONNECT_WHATS_NEW",
                                       description: "What's New",
                                       optional: true,
                                       type: String,
                                       ),

          FastlaneCore::ConfigItem.new(key: :moder_info,
                                       env_name: "RUSTORE_CONNECT_MODER_INFO",
                                       description: "Developer comment for moderator. Maximum length: 180 characters",
                                       optional: true,
                                       type: String,
                                       ),

          FastlaneCore::ConfigItem.new(key: :price_value,
                                       env_name: "RUSTORE_CONNECT_PRICE_VALUE",
                                       description: "App price in minimum currency units (in kopecks), for example, `87.99 rubles.` = 8799. Value should be >0",
                                       optional: true,
                                       type: String,
                                       ),

          FastlaneCore::ConfigItem.new(key: :seo_tag_ids,
                                       env_name: "RUSTORE_CONNECT_SEO_TAG_IDS",
                                       description: "Package name, for example `com.example.example`",
                                       optional: true,
                                       type: String,
                                       ),

          FastlaneCore::ConfigItem.new(key: :publish_type,
                                       env_name: "RUSTORE_CONNECT_PUBLISH_TYPE",
                                       description: "Publication type. Publication type: MANUAL — manual publication; INSTANTLY — automatic publication immediately after review; DELAYED — delayed publication. Note: if this parameter is not specified, then it is taken asINSTANTLY by default",
                                       optional: true,
                                       default_value: "INSTANTLY",
                                       type: String,
                                       ),

          FastlaneCore::ConfigItem.new(key: :publish_date_time,
                                       env_name: "RUSTORE_CONNECT_PUBLISH_DATE_TIME",
                                       description: "Date and time for delayed publication: format: yyyy-MM-dd'T'HH:mm:ssXXX. The specified date must be no earlier than 24 hours and no later than 60 days from the planned submission date. The delayed publication date can be changed. Note: if publishType is MANUAL или INSTANTLY, this parameter can be anything and will not be taken into account",
                                       optional: true,
                                       type: String,
                                       ),

          FastlaneCore::ConfigItem.new(key: :partial_value,
                                       env_name: "RUSTORE_CONNECT_PARTIAL_VALUE",
                                       description: "Percentage for partial publication",
                                       optional: true,
                                       type: String,
                                       ),

          FastlaneCore::ConfigItem.new(key: :services_type,
                                       env_name: "RUSTORE_CONNECT_SERVICES_TYPE",
                                       description: "Type of service used by the app. Possible options: • `HMS` — for APK files with Huawei Mobile Services; • `Unknown` is set by default if the field is empty",
                                       optional: true,
                                       default_value: "Unknown",
                                       type: String,
                                       ),

          FastlaneCore::ConfigItem.new(key: :is_main_apk,
                                       env_name: "RUSTORE_CONNECT_IS_MAIN_APK",
                                       description: "Attribute that is assigned to the main apk file. Values: • `true` — main APK file; • `false` — by default",
                                       optional: true,
                                       default_value: false,
                                       type: Boolean,
                                       ),

          FastlaneCore::ConfigItem.new(key: :apk_path,
                                       env_name: "RUSTORE_CONNECT_APK_PATH",
                                       description: "Path to APK file for upload",
                                       optional: false,
                                       type: String,
                                       ),

          FastlaneCore::ConfigItem.new(key: :is_aab,
                                       env_name: "RUSTORE_CONNECT_IS_AAB",
                                       description: "Specify this to be true if you're uploading aab instead of apk",
                                       optional: true,
                                       type: Boolean,
                                       ),

          FastlaneCore::ConfigItem.new(key: :draft_strategy,
                                       env_name: "RUSTORE_CONNECT_DRAFT_STRATEGY",
                                       description: "Strategy if draft existing. DELETE, REUSE, FAIL",
                                       optional: true,
                                       type: String,
                                       default_value: RustoreConnectDraftStrategy::FAIL,
                                       ),

          FastlaneCore::ConfigItem.new(key: :submit_for_review,
                                       env_name: "RUSTORE_CONNECT_SUBMIT_FOR_REVIEW",
                                       description: "Should submit the app for review. The default value is true. If set false will only upload the app, and you can submit for review from the console",
                                       optional: true,
                                       type: Boolean,
                                       default_value: true,
                                       )
        ]
      end

      def self.is_supported?(platform)
        [:android].include?(platform)
        true
      end
    end
  end
end
