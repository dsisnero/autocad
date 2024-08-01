module Autocad
  class Paths
    include Enumerable

    def initialize(path)
      @paths = path.split(";").map { |p| Pathname(p) }
    end

    def <<(path)
      @paths << Path(path)
    end

    def append(path)
      @paths.append Path(path)
    end

    def prepend(path)
      paths.prepend Path(path)
    end

    def each(...)
      paths.each(...)
    end

    def to_s
      parhs.join(";")
    end
  end
end
