module Autocad
  class Layer < Element
    def name
      ole_obj.name
    end

    def description
      ole_obj.description
    end
  end
end
