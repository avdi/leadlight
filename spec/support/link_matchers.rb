module Leadlight
  module LinkMatchers
    extend RSpec::Matchers::DSL

    matcher :expand_to do |expected|
      match{|actual|
        expanded == expected &&
        subscript_expanded == expected
      }

      chain(:given) do |params|
        @params = params
      end

      failure_message_for_should do |actual|
        "expected #{actual} to expand to #{expected.inspect} given " \
        "params #{@params.inspect}, but got #{expanded.inspect}"
      end

      diffable

      def expanded
        CGI.unescape(actual.expand(@params).href.to_s)
      end

      def subscript_expanded
        CGI.unescape(actual[@params].href.to_s)
      end
    end
  end
end
