require 'yaml'

def process obj
  case obj
  when String
    obj.chars.map{|x| x.ord}.join('.')
  when Array
    obj.map{|x| process x}
  when Hash
    new_hash = {}
    obj.each do |k,v|
      new_hash[process k] = process v
    end
    new_hash
  else obj
  end
end

def convert
  ymls = Dir["#{File.dirname(__FILE__)}/Characters/*.yml"]
  data = []
  ymls.each do |y|
    File.open(y, 'r:utf-8'){|f| data << YAML.load(f.read)}
  end
  File.open("Characters.data", 'wb'){|f| f.write Marshal.dump(process data)}
end

convert