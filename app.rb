require './core'

#c = Character.new(name: 'abc')
#k = [1,2,3].collect{|x| Keyword.new(name: x, character_id: 1)}
#Keyword.new(name: 'afsadfasfasd', character_id: 1)

#Character.marshal_dump
#Keyword.marshal_dump

Keyword.marshal_load
Character.marshal_load
p c = Character.find(1)
p c.keyword
p c.keyword(name: "afsadfasfasd") # shorthand of c.keyword.find(...)
