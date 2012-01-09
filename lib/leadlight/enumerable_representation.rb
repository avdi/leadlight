module Leadlight
  module EnumerableRepresentation
    Tint = Tint.new('EnumerableRepresentation') do
      match_class(Enumerable)
      extend(EnumerableRepresentation)
    end

    def each(call_super=false,&block)
      if call_super
        return super(&block)
      end

      page = self
      loop do
        page.each(true, &block)
        if (next_link = page.link('next'){nil})
          page = next_link.follow
        else
          break
        end
      end
    end
  end
end
