require './core'

Keyword.marshal_load
Character.marshal_load
Dialogue.marshal_load
puts c = Character.find(2)
p c.keyword
c.keyword.select(&:meet_requirements?).first.dialogue.perform
