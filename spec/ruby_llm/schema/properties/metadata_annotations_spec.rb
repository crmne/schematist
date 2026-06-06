# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLLM::Schema, "metadata annotations" do
  let(:schema_class) { Class.new(described_class) }

  it "supports metadata keyword arguments on primitive schemas" do
    schema_class.string :email,
                        title: "Email address",
                        description: "Primary contact email",
                        default: "user@example.com",
                        examples: ["alice@example.com"],
                        deprecated: false,
                        read_only: false,
                        write_only: true

    expect(schema_class.properties[:email]).to eq({
      type: "string",
      title: "Email address",
      description: "Primary contact email",
      default: "user@example.com",
      examples: ["alice@example.com"],
      deprecated: false,
      readOnly: false,
      writeOnly: true
    })
  end

  it "supports block annotations on object schemas" do
    schema_class.object :account do
      title "Account"
      description "Billing account metadata"
      default({status: "active"})
      examples [{id: "acct_123", status: "active"}]
      deprecated false
      read_only false
      write_only false

      string :id
      string :status
    end

    account_schema = schema_class.properties[:account]

    expect(account_schema).to include(
      title: "Account",
      description: "Billing account metadata",
      default: {status: "active"},
      examples: [{id: "acct_123", status: "active"}],
      deprecated: false,
      readOnly: false,
      writeOnly: false
    )
    expect(account_schema[:properties][:id]).to eq({type: "string"})
  end

  it "keeps keyword annotations ahead of block annotations" do
    schema_class.object :account, title: "Keyword title", description: "Keyword description" do
      title "Block title"
      description "Block description"
    end

    account_schema = schema_class.properties[:account]

    expect(account_schema[:title]).to eq("Keyword title")
    expect(account_schema[:description]).to eq("Keyword description")
  end

  it "supports current-node annotations on arrays and array items" do
    schema_class.array :events do
      description "Chronological event list"

      object do
        description "Single event payload"

        string :type
      end
    end

    events_schema = schema_class.properties[:events]

    expect(events_schema[:description]).to eq("Chronological event list")
    expect(events_schema[:items][:description]).to eq("Single event payload")
    expect(events_schema[:items][:properties][:type]).to eq({type: "string"})
  end

  it "supports current-node annotations on composition schemas" do
    schema_class.any_of :identifier do
      description "Accepted user identifier formats"

      string description: "Username"
      integer description: "Numeric user ID"
    end

    identifier_schema = schema_class.properties[:identifier]

    expect(identifier_schema[:description]).to eq("Accepted user identifier formats")
    expect(identifier_schema[:anyOf]).to eq(
      [
        {type: "string", description: "Username"},
        {type: "integer", description: "Numeric user ID"}
      ]
    )
  end

  it "supports annotations inside reusable definitions" do
    schema_class.define :address do
      title "Address"
      description "Reusable postal address schema"

      string :street
      string :city
    end

    definition = schema_class.definitions[:address]

    expect(definition[:title]).to eq("Address")
    expect(definition[:description]).to eq("Reusable postal address schema")
    expect(definition[:properties][:street]).to eq({type: "string"})
  end
end
