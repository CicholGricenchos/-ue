require './core'

Keyword.marshal_load
Character.marshal_load
Dialogue.marshal_load
puts c = Character.find(2)
p c.keyword
p c.keyword.select(&:meet_requirements?)
