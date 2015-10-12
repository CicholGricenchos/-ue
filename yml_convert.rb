require 'yaml'

def convert name
  ymls = Dir["#{File.dirname(__FILE__)}/#{name}/*.yml"]
  data = []
  ymls.each do |y|
    File.open(y, 'r:utf-8'){|f| data << YAML.load(f.read)}
  end
  File.open("#{name}.data", 'wb'){|f| f.write Marshal.dump(data)}
end

convert "Characters"
convert "Dramas"