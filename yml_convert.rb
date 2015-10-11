require 'yaml'

def convert
  ymls = Dir["#{File.dirname(__FILE__)}/Characters/*.yml"]
  data = []
  ymls.each do |y|
    File.open(y, 'r:utf-8'){|f| data << YAML.load(f.read)}
  end
  File.open("Characters.data", 'wb'){|f| f.write Marshal.dump(data)}
end

convert