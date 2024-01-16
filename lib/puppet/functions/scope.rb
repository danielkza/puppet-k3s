require 'puppet/functions'

Puppet::Functions.create_function(:'scope', Puppet::Functions::InternalFunction) do
  dispatch :scope do
    scope_param
  end

  def scope(scope)
    scope.to_hash
  end
end
