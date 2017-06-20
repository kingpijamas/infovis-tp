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
        case cast = param_definition.cast
        when nil
          next
        when Symbol
          @params[attr_name] = @params[attr_name].public_send(cast)
        else
          @params[attr_name] = cast.call(@params[attr_name])
        end
      elsif !param_definition.required?
        @params[attr_name] ||= param_definition.default_value
      end
    end
  end

  def validate_param_values!
    @param_definitions.each do |param_definition|
      next unless param_definition.required?
      next if @params.key?(param_definition.attr_name)
      raise "Missing required parameter '--#{param_definition.name}'"
    end
  end

  ParamDefinition = Struct.new(:name, :long_name, :attr_name, :default_value, :required, :cast) do
    def self.from(args)
      args = { name: param_definition } unless args.is_a? Hash

      name          = args.fetch(:name)
      long_name     = args[:long_name] || name.gsub(/-|_/, " ").capitalize
      attr_name     = (args[:attr]     || name.gsub(/-/, "_")).to_sym
      default_value = args[:default]
      required      = !args.key?(:default)
      cast          = args[:cast]

      new(name, long_name, attr_name, default_value, required, cast)
    end

    alias_method :required?, :required
  end
end
