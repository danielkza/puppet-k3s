# frozen_string_literal: true

Puppet::Type.newtype(:rke2_config) do
  @doc = <<-DOC
    @summary
      Manages an RKE2 config file.

    @example
      # The example is based on exported resources.

      rke2_config { "my-options":
        order => 10, # Optional. Default to 10
        values => {
          'hello' => 'world
        }
      }
  DOC

  newparam(:name, namevar: true) do
    desc 'Name of resource.'
  end

  newparam(:type) do
    desc <<-DOC
      Required. Specifies the type of node the config applies to.
    DOC

    newvalues(:server, :agent)
  end

  newparam(:values) do
    desc <<-DOC
      Supplies the values to be placed in the config as a Hash
    DOC

    validate do |value|
      raise ArgumentError, "Values must a hash of properties" unless value.is_a?(Hash)
    end
  end

  newparam(:order) do
    desc <<-DOC
      Order for the config file name.
    DOC

    defaultto '10'
    validate do |val|
      raise Puppet::ParseError, '$order is not a string or integer.' unless val.is_a?(String) || val.is_a?(Integer)
      raise Puppet::ParseError, 'Order cannot contain \'/\', \':\', or \'\\n\'.' if %r{[:\n/]}.match?(val.to_s)
    end
  end

  newparam(:config_path)

  autorequire(:file) do
    [config_path]
  end

  def set_sensitive_parameters(sensitive_parameters) # rubocop:disable Naming/AccessorMethodName
    # Respect sensitive https://tickets.puppetlabs.com/browse/PUP-10950
    if sensitive_parameters.include?(:values)
      sensitive_parameters.delete(:values)
      parameter(:values).sensitive = true
    end
    super(sensitive_parameters)
  end
end
