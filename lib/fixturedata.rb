require 'fixturedata/version'
require 'json'
require 'time'
require 'bson'

module HawkPrime
  # Fixture Data
  class FixtureData
    REGEX_ISODATE = /\$isodate(?:<([^>]+)>)?(?:\('([^']+)'\))?(?:\.format\('([^']+)'\))?/
    REGEX_OID = /\$oid(?:<([^>]+)>)?(\.to_s)?/

    def initialize(db, options = {})
      @options = {
        directory: 'test/fixtures',
        drop_before: true
      }.merge(options)
      @db = db
      @data = {}
      @oid_tokens = {}
      @date_tokens = {}
    end

    def load(data_dir)
      Dir["#{@options[:directory]}/#{data_dir}/*.json"].each do |file|
        load_single_file(file)
      end
    end

    def [](key)
      @data[key]
    end

    def contains?(key)
      @data.key? key
    end

    def oid(name)
      @oid_tokens[name]
    end

    private

    def load_single_file(file)
      collection = collection_name(file)
      @data[collection] = {}
      @db[collection].drop if @options[:drop_before]
      load_json(file).each do |doc_ref, document|
        result = @db[collection].insert_one(document)
        document['_id'] = result.inserted_id
        @oid_tokens["#{collection}.#{doc_ref}"] = document['_id']
        @data[collection][doc_ref] = document
      end
    end

    def collection_name(file)
      collection = File.basename(file, '.json')
      collection[collection.index('-') + 1..-1]
    end

    def load_json(file)
      json = File.read(file)
      JSON.load(json, ->(obj) { parse_objects(obj) }, create_additions: false) # rubocop:disable JSONLoad
    end

    def parse_objects(obj)
      case obj
      when Array
        obj.each_index do |index|
          obj[index] = convert_tokens(obj[index]) if obj[index].is_a? String
        end
      when Hash
        obj.each do |key, value|
          obj[key] = convert_tokens(value) if value.is_a? String
        end
      end
    end

    def convert_tokens(value)
      case value
      when REGEX_ISODATE
        convert_date(Regexp.last_match[1], Regexp.last_match[2], Regexp.last_match[3])
      when REGEX_OID
        convert_object_id(Regexp.last_match[1], !Regexp.last_match[2].nil?)
      else
        value
      end
    end

    def convert_date(tag, custom_date, date_format)
      if !tag.nil? && @date_tokens.key?(tag)
        date = @date_tokens[tag]
      else
        date = custom_date.nil? ? Time.new : Time.strptime(custom_date, '%Y-%m-%dT%H:%M:%S.%L%z')
        @date_tokens[tag] = date unless tag.nil?
      end
      return date.strftime(date_format) unless date_format.nil?
      date
    end

    def convert_object_id(tag, as_str)
      if !tag.nil? && @oid_tokens.key?(tag)
        id = @oid_tokens[tag]
      else
        id = BSON::ObjectId.new
        @oid_tokens[tag] = id unless tag.nil?
      end
      return id.to_s if as_str
      id
    end

  end
end
