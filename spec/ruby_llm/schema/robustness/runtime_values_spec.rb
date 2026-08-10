# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLLM::Schema, "runtime schema values" do
  it "evaluates proc-backed values when rendering JSON schema" do
    schema_class = Class.new(described_class) do
      def initialize(user_names:)
        super()
        @user_names = user_names
      end

      string :name, enum: -> { @user_names }
    end

    first_schema = schema_class.new(user_names: %w[Alice Bob]).to_json_schema
    second_schema = schema_class.new(user_names: %w[Carol]).to_json_schema

    expect(first_schema[:schema][:properties][:name][:enum]).to eq(%w[Alice Bob])
    expect(second_schema[:schema][:properties][:name][:enum]).to eq(%w[Carol])
    expect(schema_class.properties[:name][:enum]).to be_a(Proc)
  end

  it "evaluates runtime values inside nested schemas" do
    schema_class = Class.new(described_class) do
      def initialize(user_names:)
        super()
        @user_names = user_names
      end

      array :users do
        object do
          string :name, enum: -> { @user_names }
        end
      end
    end

    output = schema_class.new(user_names: %w[Alice Bob]).to_json_schema
    name_schema = output[:schema][:properties][:users][:items][:properties][:name]

    expect(name_schema[:enum]).to eq(%w[Alice Bob])
  end

  it "supports procs that receive the schema instance" do
    schema_class = Class.new(described_class) do
      attr_reader :allowed_roles

      def initialize(allowed_roles:)
        super()
        @allowed_roles = allowed_roles
      end

      string :role, enum: ->(schema) { schema.allowed_roles.dup }
    end

    output = schema_class.new(allowed_roles: %w[admin user]).to_json_schema

    expect(output[:schema][:properties][:role][:enum]).to eq(%w[admin user])
  end

  it "resolves runtime values in the description" do
    schema_class = Class.new(described_class) do
      description -> { "Generated for #{@audience}" }

      def initialize(audience:)
        super()
        @audience = audience
      end
    end

    expect(schema_class.new(audience: "admins").to_json_schema[:description]).to eq("Generated for admins")
  end

  it "serializes resolved values to JSON" do
    schema_class = Class.new(described_class) do
      def initialize(user_names:)
        super()
        @user_names = user_names
      end

      string :name, enum: -> { @user_names }
    end

    output = JSON.parse(schema_class.new(user_names: %w[Alice Bob]).to_json)

    expect(output.dig("schema", "properties", "name", "enum")).to eq(%w[Alice Bob])
  end
end
