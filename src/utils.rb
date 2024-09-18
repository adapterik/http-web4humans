require_relative './responses'

# Gets a value out of a JSON compatible structure 
def get_property(keys, context)
    if keys.length == 0 or context.nil?
      context
    else
      key = keys[0]
      rest = keys[1..]
      if context.is_a? Array and key.is_a? Integer
        get_property rest, context[key]
      elsif context.is_a? Object and key.is_a? Symbol
        get_property rest, context[key]
      else
        raise InternalError.new("Property not supported for #{key}")
      end
    end
  end