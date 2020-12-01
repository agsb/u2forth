
BEGIN {

#	words["noop"] = 0
#	links["noop"] = 0
#	codes["noop"] = 0
#	counts["noop"] = 0
#	states["noop"] = 0
	
	link = 0
	size = 0
	skip = 0
	count = 0
	state = 0


	FS = " "
	RS = "\n"
}

{	

for (i = 1; i <= NF; i++) {

	word = $i 

# forth comments 

	if (word == "\\" ) break

	if (word == "(" ) {

		skip = 1

		}

	if (work == ")" ) {

		skip = 0

		}

	if (skip == 1) continue

# new word

	if (state == 1) {

		if (links[word] == 0) {

			links[word] = link
	
			link = link + 1

			}

		this = word;
		
		state = 2

		}	 

	words[word] = words[word] + 1

	print "& link=" link ", this " this ", word " word "[ " links[word] " ]," " state=" state ", count=" words[word]

	if (word == ":") {

		state = 1

		this = ""

		continue;

		}
	
	if (word == ";") {

		state = 0;
		
		codes[this] = codes[this] ", "  links[";"]

		continue;

		}

	if (codes[this] == "") {

		codes[this] =  links[this] ", " links[":"]

		}
 
	codes[this] = codes[this] ", "  links[word] 


	}

}

END {

	for (word in words) {

		print " link= " links[word] " , word= " word " , count= ", words[word] " , state= " states[word] ", codes ( " codes[word] " ) "
		
		}
}


