# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLLM::Schema, "factory method (.create) approach" do
  include SchemaBuilders

  describe "schema attributes" do
    let(:base_schema) { build_factory_schema { string :title } }

    it "derives schema names from constants, instances, and defaults" do
      stub_const("NamedFactorySchema", build_factory_schema { string :title })
      expect(NamedFactorySchema.new.to_ruby_llm_schema[:name]).to eq("NamedFactorySchema")

      expect(base_schema.new.to_ruby_llm_schema[:name]).to eq("Schema")
      expect(base_schema.new("CustomName").to_ruby_llm_schema[:name]).to eq("CustomName")
    end

    it "honours description precedence" do
      schema_with_description = build_factory_schema do
        description "Factory description"
        string :title
      end

      anonymous_output = base_schema.new.to_ruby_llm_schema
      expect(anonymous_output[:description]).to be_nil

      class_level_output = schema_with_description.new.to_ruby_llm_schema
      expect(class_level_output[:description]).to eq("Factory description")

      instance_override = schema_with_description.new("NamedSchema", description: "Instance description").to_ruby_llm_schema
      expect(instance_override[:description]).to eq("Instance description")
    end

    it "controls additional properties and strictness" do
      default_output = base_schema.new.to_ruby_llm_schema
      expect(default_output[:schema][:additionalProperties]).to eq(false)
      expect(default_output[:schema][:strict]).to eq(true)

      configured_schema = build_factory_schema do
        additional_properties true
        strict false
        string :title
      end

      configured_output = configured_schema.new.to_ruby_llm_schema
      expect(configured_output[:schema][:additionalProperties]).to eq(true)
      expect(configured_output[:schema][:strict]).to eq(false)
    end

    it "renders structured JSON schema" do
      configured_schema = build_factory_schema do
        description "Factory test description"
        additional_properties false
        string :title
        integer :count, required: false
      end

      output = configured_schema.new("FactoryConfiguredSchema").to_ruby_llm_schema

      expect(output).to include(
        name: "FactoryConfiguredSchema",
        description: "Factory test description",
        schema: hash_including(
          type: "object",
          properties: {
            title: {type: "string"},
            count: {type: "integer"}
          },
          required: [:title],
          additionalProperties: false,
          strict: true
        )
      )
    end
  end

  describe "comprehensive scenario" do
    let(:schema_class) do
      build_factory_schema do
        description "Comprehensive factory schema"
        additional_properties true
        strict true

        string :name, description: "Name field"
        integer :count
        boolean :active, required: false

        object :config do
          string :setting
        end

        array :tags, of: :string

        any_of :status do
          string
          null
        end
      end
    end

    it "supports full-feature schemas" do
      json_output = schema_class.new("FactorySchema").to_ruby_llm_schema

      expect(json_output[:name]).to eq("FactorySchema")
      expect(json_output[:schema][:additionalProperties]).to eq(true)
      expect(json_output[:schema][:strict]).to eq(true)
      expect(json_output[:schema][:properties].keys).to contain_exactly(
        :name, :count, :active, :config, :tags, :status
      )
      expect(json_output[:schema][:required]).to contain_exactly(:name, :count, :config, :tags, :status)
    end
  end
end
