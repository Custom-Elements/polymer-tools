docs:
	echo '```' > README.md
	./bin/polymer-build --help >> README.md
	echo '```' >> README.md
