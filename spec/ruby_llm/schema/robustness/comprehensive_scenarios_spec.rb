# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLLM::Schema, "comprehensive scenarios" do
  include SchemaBuilders

  it "handles edge cases" do
    empty_output = build_schema_class.new("EmptySchema").to_ruby_llm_schema
    expect(empty_output[:schema][:properties]).to eq({})
    expect(empty_output[:schema][:required]).to eq([])

    optional_output = build_schema_class {
      string :optional1, required: false
      integer :optional2, required: false
    }.new.to_ruby_llm_schema

    expect(optional_output[:schema][:required]).to eq([])
    expect(optional_output[:schema][:properties].keys).to contain_exactly(:optional1, :optional2)
  end

  it "handles complex nested structures with all features" do
    complex_output = build_schema_class {
      string :id, description: "Unique identifier"

      object :metadata do
        string :created_by
        integer :version
        boolean :published, required: false
      end

      array :tags, of: :string, description: "Resource tags"

      array :items do
        object do
          string :name
          any_of :value do
            string
            number
            boolean
            null
          end
        end
      end

      any_of :status do
        string enum: %w[draft published]
        null
      end

      define :author do
        string :name
        string :email
      end

      array :authors, of: :author
    }.new("ComplexSchema").to_ruby_llm_schema

    expect(complex_output[:schema][:properties].keys).to contain_exactly(
      :id, :metadata, :tags, :items, :status, :authors
    )
    expect(complex_output[:schema]["$defs"][:author]).to be_a(Hash)
    expect(complex_output[:schema][:required]).to include(:id, :metadata, :tags, :items, :status, :authors)
    expect(complex_output[:schema][:properties][:id][:description]).to eq("Unique identifier")
    expect(complex_output[:schema][:properties][:tags][:description]).to eq("Resource tags")
  end
end
