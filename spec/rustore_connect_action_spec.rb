require 'rspec'
require 'fastlane'
require_relative '../lib/fastlane/plugin/rustore_connect/actions/rustore_connect_action'
require_relative '../lib/fastlane/plugin/rustore_connect/helper/rustore_connect_helper'
require_relative '../lib/fastlane/plugin/rustore_connect/lib/rustore_connect_draft_strategy'

RSpec.describe Fastlane::Actions::RustoreConnectAction do
  let(:params) do
    {
      key_id: "key123",
      private_key: "privkey",
      package_name: "com.example.app",
      app_name: "Test App",
      app_type: "GAMES",
      categories: ["games"],
      age_legal: "3+",
      short_description: "Short desc",
      full_description: "Full desc",
      whats_new: "New stuff",
      moder_info: "Info",
      price_value: "0",
      seo_tag_ids: [],
      publish_type: "INSTANTLY",
      publish_date_time: nil,
      partial_value: nil,
      services_type: "Unknown",
      is_main_apk: true,
      apk_path: "spec/fixtures/app-release.aab",
      is_aab: true,
      draft_strategy: RustoreConnectDraftStrategy::FAIL,
      submit_for_review: true
    }
  end

  let(:token) { "fake_token" }
  let(:version_id) { 123 }

  before do
    FileUtils.mkdir_p("spec/fixtures")
    File.write(params[:apk_path], "fake content")
  end

  after do
    File.delete(params[:apk_path]) if File.exist?(params[:apk_path])
  end

  context "when no draft exists" do
    it "creates a new draft and uploads" do
      expect(Fastlane::Helper::RustoreConnectHelper).to receive(:get_token).and_return(token)
      expect(Fastlane::Helper::RustoreConnectHelper).to receive(:get_app_versions).and_return(nil)
      expect(Fastlane::Helper::RustoreConnectHelper).to receive(:create_draft).and_return(version_id)
      expect(Fastlane::Helper::RustoreConnectHelper).to receive(:upload).with(
        token,
        params[:package_name],
        version_id,
        params[:is_aab],
        params[:apk_path],
        params[:services_type],
        params[:is_main_apk]
      ).and_return(true)
      expect(Fastlane::Helper::RustoreConnectHelper).to receive(:commit_version).and_return(true)

      described_class.run(params)
    end
  end

  context "when draft exists and strategy is DELETE" do
    it "deletes old draft, creates new one and uploads" do
      params[:draft_strategy] = RustoreConnectDraftStrategy::DELETE

      expect(Fastlane::Helper::RustoreConnectHelper).to receive(:get_token).and_return(token)
      expect(Fastlane::Helper::RustoreConnectHelper).to receive(:get_app_versions).and_return(version_id)
      expect(Fastlane::Helper::RustoreConnectHelper).to receive(:delete_draft).with(token, params[:package_name], version_id)
      expect(Fastlane::Helper::RustoreConnectHelper).to receive(:create_draft).and_return(999)
      expect(Fastlane::Helper::RustoreConnectHelper).to receive(:upload)
      expect(Fastlane::Helper::RustoreConnectHelper).to receive(:commit_version)

      described_class.run(params)
    end
  end

  context "when draft exists and strategy is REUSE" do
    it "reuses existing draft and uploads" do
      params[:draft_strategy] = RustoreConnectDraftStrategy::REUSE

      expect(Fastlane::Helper::RustoreConnectHelper).to receive(:get_token).and_return(token)
      expect(Fastlane::Helper::RustoreConnectHelper).to receive(:get_app_versions).and_return(version_id)
      expect(Fastlane::Helper::RustoreConnectHelper).not_to receive(:delete_draft)
      expect(Fastlane::Helper::RustoreConnectHelper).not_to receive(:create_draft)
      expect(Fastlane::Helper::RustoreConnectHelper).to receive(:upload)
      expect(Fastlane::Helper::RustoreConnectHelper).to receive(:commit_version)

      described_class.run(params)
    end
  end

  context "when draft exists and strategy is FAIL" do
    it "raises an error" do
      params[:draft_strategy] = RustoreConnectDraftStrategy::FAIL

      expect(Fastlane::Helper::RustoreConnectHelper).to receive(:get_token).and_return(token)
      expect(Fastlane::Helper::RustoreConnectHelper).to receive(:get_app_versions).and_return(version_id)

      expect {
        described_class.run(params)
      }.to raise_error(FastlaneCore::Interface::FastlaneError, /Draft already exists/)
    end
  end

  context "when unknown draft_strategy provided" do
    it "raises an error" do
      params[:draft_strategy] = "INVALID_STRATEGY"

      expect(Fastlane::Helper::RustoreConnectHelper).to receive(:get_token).and_return(token)
      expect(Fastlane::Helper::RustoreConnectHelper).to receive(:get_app_versions).and_return(version_id)

      expect {
        described_class.run(params)
      }.to raise_error(FastlaneCore::Interface::FastlaneError, /Unknown draft_strategy/)
    end
  end

  context "when token is nil" do
    it "shows message and skips upload" do
      expect(Fastlane::Helper::RustoreConnectHelper).to receive(:get_token).and_return(nil)
      expect(Fastlane::Helper::RustoreConnectHelper).not_to receive(:get_app_versions)

      described_class.run(params)
    end
  end
end