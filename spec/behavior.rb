require "rspec"
require "async/prefix"
using Async::Prefix
RSpec.describe do
  let!(:Cls) do
    class Cls
      async def hello
        "hello"
      end

      async def param(proto)
        proto * 2
      end

      async def param_block(&block)
        block
      end

      async def param_yield
        yield
      end
    end
  end
  let (:cls) { Cls.new }
  context "#hello" do
    let (:hello) { cls.hello }
    it "should return Async::Task" do
      expect(hello).to be_a(Async::Task)
    end
    it "should return hello on #wait" do
      expect(hello.wait).to eq "hello"
    end
  end
  context "#param" do
    let (:param) { cls.param(42) }
    it "should return Async::Task" do
      expect(param).to be_a(Async::Task)
    end
    it "should return 20 on #wait" do
      expect(param.wait).to eq 42 * 2
    end
    it "should raise ArgumentError" do
      expect { cls.param }.to raise_error(ArgumentError)
    end
  end
  context "#param_block" do
    let (:param_block) { cls.param_block { "hello" } }
    it "should return Async::Task" do
      expect(param_block).to be_a(Async::Task)
    end
    it "should return Proc on #wait" do
      expect(param_block.wait).to be_a(Proc)
    end
  end
  context "#param_yield" do
    let (:param_yield) { cls.param_yield { "hello" } }
    it "should return Async::Task" do
      expect(param_yield).to be_a(Async::Task)
    end
    it "should return hello on #wait" do
      expect(param_yield.wait).to eq "hello"
    end
  end
end
