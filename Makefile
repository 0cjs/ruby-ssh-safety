
all: Test.rb Test.md

Test.rb:
	literate_md -f Test.litrb -t

Test.md:
	literate_md -f Test.litrb -w
