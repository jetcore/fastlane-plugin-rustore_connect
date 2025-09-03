require 'rspec'
require 'webmock/rspec'
require_relative '../lib/fastlane/plugin/rustore_connect/helper/rustore_connect_helper'

RSpec.describe Fastlane::Helper::RustoreConnectHelper do
  let(:token) { "fake_token" }
  let(:package_name) { "com.example.app" }
  let(:version_id) { 12345 }
  let(:base_url) { "https://public-api.rustore.ru" }

  before do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  describe '.get_token' do
    let(:key_id) { 'test-key-id' }
    let(:private_key) { 'FAKE_PRIVATE_KEY' }

    before do
      # Мокаем RSA, чтобы не использовать реальный приватный ключ
      fake_rsa = instance_double(OpenSSL::PKey::RSA)
      allow(OpenSSL::PKey::RSA).to receive(:new).and_return(fake_rsa)
      allow(fake_rsa).to receive(:sign).and_return('fake-signature')
      allow(Base64).to receive(:encode64).and_return('fake-signature-encoded')

      # Успешный ответ по умолчанию
      stub_request(:post, "https://public-api.rustore.ru/public/auth")
        .to_return(
          status: 200,
          body: {
            "code" => "OK",
            "body" => { "jwe" => "FAKE_JWE_TOKEN" }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns a token when response is OK' do
      token = described_class.get_token(key_id, private_key)
      expect(token).to eq("FAKE_JWE_TOKEN")
    end

    it 'returns nil when response body has no jwe' do
      # Если ответ вернулся, но внутри body нет поля "jwe"
      stub_request(:post, "https://public-api.rustore.ru/public/auth")
        .to_return(
          status: 200,
          body: {
            "code" => "OK",
            "body" => {}
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      token = described_class.get_token(key_id, private_key)
      expect(token).to be_nil
    end

    it 'returns nil when response is not OK' do
      # Если ответ вернулся с кодом ERROR
      stub_request(:post, "https://public-api.rustore.ru/public/auth")
        .to_return(
          status: 200,
          body: {
            "code" => "ERROR",
            "message" => "Invalid credentials"
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      token = described_class.get_token(key_id, private_key)
      expect(token).to be_nil
    end
  end

  describe ".get_app_versions" do
    context "when response is OK with one element" do
      it "returns versionId" do
        stub_request(:get, "#{base_url}/public/v1/application/#{package_name}/version")
          .to_return(status: 200, body: {
            code: "OK",
            body: { content: [{ "versionId" => version_id }] }
          }.to_json)

        result = described_class.get_app_versions(token, package_name)
        expect(result).to eq(version_id)
      end
    end

    context "when response has no content" do
      it "returns nil" do
        stub_request(:get, "#{base_url}/public/v1/application/#{package_name}/version")
          .to_return(status: 200, body: {
            code: "OK",
            body: { content: [] }
          }.to_json)

        result = described_class.get_app_versions(token, package_name)
        expect(result).to be_nil
      end
    end

    context "when response has more than one version" do
      it "raises an error" do
        stub_request(:get, "#{base_url}/public/v1/application/#{package_name}/version")
          .to_return(status: 200, body: {
            code: "OK",
            body: { content: [{ versionId: 1 }, { versionId: 2 }] }
          }.to_json)

        expect {
          described_class.get_app_versions(token, package_name)
        }.to raise_error("Expected a single element in 'content', but found: 2")
      end
    end
  end

  describe ".create_draft" do
    it "returns version_id when response is OK" do
      stub_request(:post, "#{base_url}/public/v1/application/#{package_name}/version")
        .to_return(status: 200, body: {
          code: "OK",
          body: version_id
        }.to_json)

      result = described_class.create_draft(token, package_name, "AppName", "AppType", ["category"], "3+",
                                            "Short", "Full", "New", "Info", "0", [],
                                            "AUTO", nil, nil)
      expect(result).to eq(version_id)
    end

    it "raises error when response fails" do
      stub_request(:post, "#{base_url}/public/v1/application/#{package_name}/version")
        .to_return(status: 400, body: {
          code: "ERROR",
          message: "Invalid data"
        }.to_json)

      expect {
        described_class.create_draft(token, package_name, "AppName", "AppType", ["category"], "3+",
                                     "Short", "Full", "New", "Info", "0", [],
                                     "AUTO", nil, nil)
      }.to raise_error("Invalid data")
    end
  end

  describe ".delete_draft" do
    it "returns true when draft deleted" do
      stub_request(:delete, "#{base_url}/public/v1/application/#{package_name}/version/#{version_id}")
        .to_return(status: 200, body: { code: "OK" }.to_json)

      result = described_class.delete_draft(token, package_name, version_id)
      expect(result).to eq(true)
    end
  end

  describe ".commit_version" do
    it "returns true when commit successful" do
      stub_request(:post, "#{base_url}/public/v1/application/#{package_name}/version/#{version_id}/commit")
        .to_return(status: 200, body: { code: "OK" }.to_json)

      result = described_class.commit_version(token, package_name, version_id)
      expect(result).to eq(true)
    end
  end

  describe ".upload" do
    let(:file_path) { "spec/fixtures/app-release.aab" }

    before do
      FileUtils.mkdir_p("spec/fixtures")
      File.write(file_path, "dummy content")
    end

    after do
      File.delete(file_path) if File.exist?(file_path)
    end

    it "uploads AAB file successfully" do
      stub_request(:post, "#{base_url}/public/v1/application/#{package_name}/version/#{version_id}/aab")
        .to_return(status: 200, body: { code: "OK" }.to_json)

      result = described_class.upload(token, package_name, version_id, true, file_path)
      expect(result).to eq(true)
    end

    it "raises error if file doesn't exist" do
      expect {
        described_class.upload(token, package_name, version_id, true, "nonexistent.aab")
      }.to raise_error(/File not found/)
    end
  end
end