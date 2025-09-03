require 'fastlane_core/ui/ui'
require 'net/http'
require 'uri'
require 'json'
require 'net/http/post/multipart'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?(:UI)

  module Helper
    class RustoreConnectHelper
      def self.rsa_sign(timestamp, key_id, private_key)
        key = OpenSSL::PKey::RSA.new("-----BEGIN RSA PRIVATE KEY-----\n#{private_key}\n-----END RSA PRIVATE KEY-----")
        signature = key.sign(OpenSSL::Digest.new('SHA512'), key_id + timestamp)
        Base64.encode64(signature)
      end

      def self.get_token(key_id, private_key)
        UI.important("Fetching app access token")

        uri = URI.parse('https://public-api.rustore.ru/public/auth')
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Post.new(uri.path)

        request["Content-Type"] = "application/json"

        timestamp = DateTime.now.iso8601(3)
        signature = rsa_sign(timestamp, key_id, private_key)

        request.body = { keyId: key_id, timestamp: timestamp, signature: signature }.to_json
        response = http.request(request)

        UI.message("Debug: response #{response.body}")

        # Если не 200 — возвращаем nil
        return nil unless response.is_a?(Net::HTTPSuccess)

        result_json = JSON.parse(response.body) rescue nil
        return nil unless result_json && result_json["body"]

        return result_json["body"]["jwe"]
      end

      def self.get_app_versions(token, package_name, ids: nil, version_statuses: nil, filter_testing_type: nil, page: nil, size: nil)
        uri = URI.parse("https://public-api.rustore.ru/public/v1/application/#{package_name}/version")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        uri.query = URI.encode_www_form(
          {
            ids: ids,
            versionStatuses: version_statuses,
            filterTestingType: filter_testing_type,
            page: page,
            size: size
          }.compact
        )

        request = Net::HTTP::Get.new(uri)

        request["Content-Type"] = "application/json"
        request["Public-Token"] = token

        response = http.request(request)

        result_json = JSON.parse(response.body)

        UI.message("Debug: response #{response.body}")
        if result_json["code"] == 'OK'
          body = result_json["body"]
          content = body["content"]

          # Check that content is an array
          unless content.is_a?(Array)
            raise "Invalid RuStore response format: 'content' array is missing"
          end

          # If there are no elements — return nil
          return nil if content.empty?

          # If there are more than one element — raise an error
          if content.size > 1
            raise "Expected a single element in 'content', but found: #{content.size}"
          end

          # Return the id of the first element
          return content.first["versionId"]
        else
          raise "Couldn't get draftId from RuStore: #{result_json['message'] || 'Unknown error'}"
        end

      end

      def self.create_draft(
        token,
        package_name,
        app_name,
        app_type,
        categories,
        age_legal,
        short_description,
        full_description,
        whats_new,
        moder_info,
        price_value,
        seo_tag_ids,
        publish_type,
        publish_date_time,
        partial_value
      )
        uri = URI.parse("https://public-api.rustore.ru/public/v1/application/#{package_name}/version")

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Post.new(uri)

        request["Content-Type"] = "application/json"
        request["Public-Token"] = token

        request.body = {
          appName: app_name,
          appType: app_type,
          categories: categories,
          ageLegal: age_legal,
          shortDescription: short_description,
          fullDescription: full_description,
          whatsNew: whats_new,
          moderInfo: moder_info,
          priceValue: price_value,
          seoTagIds: seo_tag_ids,
          publishType: publish_type,
          publishDateTime: publish_date_time,
          partialValue: partial_value
        }.to_json

        response = http.request(request)

        result_json = JSON.parse(response.body)

        UI.message("Debug: response #{response.body}")

        if result_json["code"] == "OK"
          version_id = result_json["body"]
          if version_id
            return version_id
          else
            raise "Missing versionId in response body"
          end
        else
          message = result_json["message"] || "Couldn't create draft on RuStore"
          raise message
        end
      end

      def self.delete_draft(
        token,
        package_name,
        version_id
      )
        uri = URI.parse("https://public-api.rustore.ru/public/v1/application/#{package_name}/version/#{version_id}")

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Delete.new(uri)

        request["Content-Type"] = "application/json"
        request["Public-Token"] = token

        response = http.request(request)
        result_json = JSON.parse(response.body)

        UI.message("Debug: response #{response.body}")

        if result_json["code"] == "OK"
          UI.message("Draft version #{version_id} deleted successfully.")
          return true
        else
          message = result_json["message"] || "Failed to delete draft version #{version_id}"
          raise message
        end
      end

      def self.commit_version(token, package_name, version_id)
        uri = URI.parse("https://public-api.rustore.ru/public/v1/application/#{package_name}/version/#{version_id}/commit")

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "application/json"
        request["Public-Token"] = token

        response = http.request(request)
        result_json = JSON.parse(response.body)

        UI.message("Debug: response #{response.body}") if ENV['DEBUG']

        if result_json["code"] == "OK"
          UI.message("Draft version #{version_id} committed successfully.")
          return true
        else
          message = result_json["message"] || "Failed to commit draft version #{version_id}"
          raise message
        end
      end

      def self.upload(token, package_name, version_id, is_aab, file_path, services_type = nil, is_main_apk = nil)
        file_path = File.expand_path(file_path, Dir.pwd)
        raise "File not found: #{file_path}" unless File.exist?(file_path)

        file_name = File.basename(file_path)

        if is_aab
          # Загрузка AAB
          uri = URI.parse("https://public-api.rustore.ru/public/v1/application/#{package_name}/version/#{version_id}/aab")
          payload = { "file" => UploadIO.new(file_path, "application/vnd.android.package-archive", file_name) }
        else
          # Загрузка APK
          raise ArgumentError, "is_main_apk is required for APK upload" if is_main_apk.nil?

          services_type ||= "Unknown"
          uri = URI.parse("https://public-api.rustore.ru/public/v1/application/#{package_name}/version/#{version_id}/apk")
          uri.query = URI.encode_www_form({ isMainApk: is_main_apk, servicesType: services_type })
          payload = { "file" => UploadIO.new(file_path, "application/vnd.android.package-archive", file_name) }
        end

        request = Net::HTTP::Post::Multipart.new(uri, payload)
        request["Public-Token"] = token

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.open_timeout = 60      # время на открытие соединения
        http.read_timeout = 600     # время на чтение ответа (подойдет для больших файлов)
        http.write_timeout = 600    # время на отправку файла

        response = http.request(request)
        result_json = JSON.parse(response.body)

        UI.message("Debug: response #{response.body}")

        if result_json["code"] == "OK"
          UI.message("#{file_name} uploaded successfully.")
          true
        else
          message = result_json["message"] || "Failed to upload file"
          if message.include?("The code of this version must be larger")
            raise "Build with this version code was already uploaded earlier"
          else
            raise message
          end
        end
      end

    end
  end
end
