require "fileutils"
require "optparse"

class ScriptParams
  attr_reader :params

  def self.read!(*raw_param_definitions)
    new(*raw_param_definitions).read!
  end

  def initialize(*raw_param_definitions)
    @param_definitions = raw_param_definitions.map(&ParamDefinition.method(:from))
    @params            = {}
  end

  def read!
    opt_parser.parse!
    populate_params!
    validate_param_values!
    params
  end

  private

  def opt_parser
    @opt_parser ||= OptionParser.new do |opts|
      opts.banner = "Usage: #{File.basename(__FILE__)} [params]"

      @param_definitions.each do |param_definition|
        opts.on("--#{param_definition.name} value", param_definition.long_name) do |attr_value|
          params[param_definition.attr_name] = attr_value if attr_value
        end
      end
    end
  end

  def populate_params!
    @param_definitions.each do |param_definition|
      attr_name = param_definition.attr_name

      if @params.key?(attr_name)
        apply_cast!(param_definition)
      elsif !param_definition.required?
        @params[attr_name] ||= param_definition.default_value
        apply_cast!(param_definition) if param_definition.cast_all?
      end
    end
  end

  def apply_cast!(param_definition)
    attr_name = param_definition.attr_name

    case cast = param_definition.cast
    when nil
      return
    when Symbol
      @params[attr_name] = @params[attr_name].public_send(cast)
    else
      @params[attr_name] = cast.call(@params[attr_name])
    end
  end

  def validate_param_values!
    @param_definitions.each do |param_definition|
      next unless param_definition.required?
      next if @params.key?(param_definition.attr_name)
      raise "Missing required parameter '--#{param_definition.name}'"
    end
  end

  ParamDefinition = Struct.new(:name, :long_name, :attr_name, :default_value, :required, :cast_schema) do
    def self.from(args)
      args = { name: param_definition } unless args.is_a? Hash

      name          = args.fetch(:name)
      long_name     = args[:long_name] || name.gsub(/-|_/, " ").capitalize
      attr_name     = (args[:attr]     || name.gsub(/-/, "_")).to_sym
      default_value = args[:default]
      required      = !args.key?(:default)
      cast_schema   =
        case args[:cast]
        when Hash
          args[:cast]
        else
          { value: args[:cast], mode: :given_only }
        end

      new(name, long_name, attr_name, default_value, required, cast_schema)
    end

    def cast_all?
      cast_mode == :all
    end

    def cast
      return unless cast_schema
      cast_schema.fetch(:value)
    end

    def cast_mode
      return unless cast_schema
      cast_schema.fetch(:mode)
    end

    alias_method :required?, :required
  end
end
