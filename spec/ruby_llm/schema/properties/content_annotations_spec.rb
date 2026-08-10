# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLLM::Schema, "content annotations" do
  let(:schema_class) { Class.new(described_class) }

  it "supports contentEncoding and contentMediaType keywords" do
    schema_class.string :payload,
                        content_encoding: "base64",
                        content_media_type: "application/json"

    expect(schema_class.properties[:payload]).to eq({
      type: "string",
      contentEncoding: "base64",
      contentMediaType: "application/json"
    })
  end

  it "supports nested contentSchema blocks" do
    schema_class.string :payload,
                        content_encoding: "base64",
                        content_media_type: "application/json" do
      content_schema do
        object do
          title "Payload"
          description "Decoded JSON payload"

          string :name
        end
      end
    end

    payload_schema = schema_class.properties[:payload]

    expect(payload_schema[:contentSchema]).to include(
      type: "object",
      title: "Payload",
      description: "Decoded JSON payload"
    )
    expect(payload_schema[:contentSchema][:properties][:name]).to eq({type: "string"})
  end

  it "supports a primitive contentSchema" do
    schema_class.string :payload, content_media_type: "text/plain" do
      content_schema do
        string pattern: "^[a-z]+$"
      end
    end

    expect(schema_class.properties[:payload][:contentSchema]).to eq({type: "string", pattern: "^[a-z]+$"})
  end

  it "supports metadata on the encoded string node" do
    schema_class.string :payload, title: "Encoded payload" do
      content_schema do
        object do
          string :name
        end
      end
    end

    payload_schema = schema_class.properties[:payload]

    expect(payload_schema[:title]).to eq("Encoded payload")
    expect(payload_schema[:contentSchema][:properties][:name]).to eq({type: "string"})
  end
end
