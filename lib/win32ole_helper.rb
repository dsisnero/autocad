module WIN32OLE::Helper
  def help(method_name)
    method = ole_methods.find { |m| m.name.casecmp?(method_name.to_s) }
    return "Method #{method_name} not found" unless method

    params_info = method.params.map.with_index(1) do |param, i|
      [
        "Parameter #{i}: #{param.name}",
        "Type: #{param.ole_type}",
        "Direction: #{param.input? ? 'Input' : ''}#{param.output? ? 'Output' : ''}",
        "Optional: #{param.optional? ? 'Yes' : 'No'}",
        "Default: #{param.default if param.optional?}"
      ].compact.join("\n  ")
    end.join("\n\n")

    tips = []
    tips << "Contains VARIANT parameters - use WIN32OLE_VARIANT.new(value)" if method.params.any? { |p| p.ole_type == 'VARIANT' }
    tips << "Has output parameters - returns [return_value, *outputs]" if method.params.any?(&:output?)

    <<~HELP
      Method: #{method.name}
      Return Type: #{method.return_type}
      Description: #{method.helpstring}

      Parameters:
      #{params_info}

      #{tips.join("\n")}
    HELP
  end

  def help_methods
    ole_methods.map(&:name).sort
  end

  def self.extended(obj)
    obj.instance_exec do
      # Add COM method completion if in IRB
      if defined?(IRB)
        def method_missing(method, *args)
          super
        rescue WIN32OLERuntimeError => e
          if e.message.include?('Unknown name')
            similar = help_methods.grep(/#{method.to_s}/i)
            raise NoMethodError, "#{method}. Did you mean?\n#{similar.join("\n")}"
          end
          raise
        end
      end
    end
  end
end
