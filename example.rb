require "async/prefix"

using Async::Prefix

class Example
  attr_reader :main_queue, :logger

  def initialize
  end

  async def test
    puts "test"
    sleep 5
    puts "test2"
  end
end

example = Example.new
example.test
