#encoding: utf-8

obj = "keywords"
#File.open('test', 'wb'){|f| f.write Marshal.dump(obj)}

Marshal.load(File.open('Lille/test.data', &:read))

#trav obj
#p obj