# frozen_string_literal: true

module Ask
  module AnyChat
    # Everything this gem raises, under one parent, so a caller can rescue the
    # library rather than a list of its moods. Each one carries the sentence the
    # API answered with: "An agent needs a name." is worth more than "422".
    class Error < StandardError
      # The token was missing, expired, or refused.
      class Unauthorized < Error; end

      # No such workspace — or none this token can reach, which is the same
      # answer on purpose.
      class NotFound < Error; end

      # The API understood the request and refused it; the message says why.
      class Invalid < Error; end

      # The API failed, or answered with something this gem did not expect.
      class Api < Error; end

      # The API could not be reached at all.
      class Unreachable < Error; end
    end
  end
end
