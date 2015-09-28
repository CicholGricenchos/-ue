
class Model
  attr_accessor :data

  class << self
    attr_accessor :all_items

    def has_many n
      define_method n do
        Result.new Model.const_get(n.capitalize).all_items.select{|x| x.send("#{self.class.name.downcase}_id") == self.id}
      end
    end

    def belongs_to n
      define_method n do
        Model.const_get(n.capitalize).all_items.select{|x| x.id == self.send("#{n}_id")}.first
      end
    end

    def marshal_load
      Marshal.load(File.open("#{self.name}.data"){|f| f.read }).each{|h| self.new h }
    end

    def marshal_dump
      File.open("#{self.name}.data", 'wb'){|f| f.write Marshal.dump(@all_items.collect(&:data))}
    end

    def all
      Result.new @all_items
    end

    def find param
      self.all.find param
    end

  end

  def initialize data
    @data = data
    self.class.all_items ||= []
    @data[:id] ||= self.class.all_items.empty? ? 1 : self.class.all_items.last.id + 1
    self.class.all_items << self
  end

  # getting data
  def method_missing name
    @data[name]
  end

  def inspect
    str = @data.reject{|k| k == :id}.map{|k,v| ":#{k}=>#{v.inspect}"}.join ', '
    "#<#{self.class.name}##{@data[:id].to_s.rjust(4,'0')} {#{str}}>"
  end

  class Result < Array
    def find param
      case param
      when String
        # an SQL parser is needed here
      when Hash
        self.select{|x| param.all?{|k,v| x.send(k) == v}}
      end
    end

  end

end


class Character < Model
  has_many :keyword

end

class Keyword < Model
  belongs_to :character

end

#c = Character.new(name: 'abc')
#k = [1,2,3].collect{|x| Keyword.new(name: x, character_id: 1)}
#Keyword.new(name: 'afsadfasfasd', character_id: 1)

#Character.marshal_dump
#Keyword.marshal_dump

Keyword.marshal_load
Character.marshal_load
p Keyword.all.first.character