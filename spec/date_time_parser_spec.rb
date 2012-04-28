
require_relative 'spec_helper'
require 'callfuture.me/date_time_parser'

describe CallFutureMe::DateTimeParser do
  Parser = CallFutureMe::DateTimeParser

  def parse(str)
    now = Time.local(2012, 1, 1, 3)
    Parser.parse(str, :now => now)
  end

  it "can parse all kinds of strings" do
    # XXX: I don't actually know what Twilio is going to give us, let's just
    # make a random list here

    parse('12:05pm').must_equal Time.local(2012, 1, 1, 12, 5)
    parse('9:19pm').must_equal Time.local(2012, 1, 1, 9, 19)

    parse('today at 12:05pm').must_equal Time.local(2012, 1, 1, 12, 5)
    parse('tomorrow at 9:19pm').must_equal Time.local(2012, 1, 2, 9, 19)

    parse('five hours from now').must_equal Time.local(2012, 1, 6, 3)

    assert_raise(Parser::TimeComponentMissing) do
      parse('tomorrow')
    end
  end
end
