module Leadlight
  module LinkMatchers
    extend RSpec::Matchers::DSL

    matcher :expand_to do |expected|
      match{|actual|
        @failures = []
        href_matches?(actual, expected) && params_match?(actual, expected)
      }

      chain(:given) do |params|
        @params = params
      end

      chain(:with_params) do |expected_params|
        @expected_params = expected_params
      end

      failure_message_for_should do |actual|
        @failures.join("\n")
      end

      def expanded
        CGI.unescape(expanded_link.href.to_s)
      end

      def expanded_link
        actual.expand(@params)
      end

      def subscript_expanded
        CGI.unescape(actual[@params].href.to_s)
      end

      def params_match?(actual, expected)
        if defined?(@expected_params)
          @expected_params.each do |key, value|
            unless expanded_link.params[key] == value
              @failures << "Expected #{expanded_link.params.inspect} to include "\
                           "#{key.inspect} => #{value.inspect}"
              return false
            end
          end
        end
        return true
      end

      def href_matches?(actual, expected)
        if expanded == expected && subscript_expanded == expected
          true
        else
          @failures << "expected #{actual} to expand to #{expected.inspect} given " \
                       "params #{@params.inspect}, but got #{expanded.inspect}"
          false
        end
      end
    end
  end
end
