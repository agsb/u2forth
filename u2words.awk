
BEGIN {

#	words["noop"] = 0
#	links["noop"] = 0
#	codes["noop"] = 0
#	counts["noop"] = 0
#	states["noop"] = 0
	
	link = 1

	skip = 0

	state = 0

	FS = " "

	RS = "\n"

}

{	

for (i = 1; i <= NF; i++) {

	word = $i 

# skip forth comments 

	if (state != 1) {  # not a name ?
	
		if (word == "\\" ) {

			if (state != 1) break

			}

		if (word == "(" ) {

			skip = 1

			}

		if (work == ")" ) {

			skip = 0

			}
		}

	if (skip == 1) continue

# counts word

	words[word] = words[word] + 1

# new word ? 

	if (links[word] == 0) {

		link = link + 1

		print "& " link " got new word " word  

		links[word] = link

		}

# compiler word

	if (state == 0) {

		if (word == ":") {

			state = 1

			this = ""

			print "& " link " got colon "

			}	

		else {	

			if (word == "IMMEDIATE") {

				status[this] = 1

				print "& " link " got immediate " this  

				}
			
			if (word == "COMPILE-ONLY") {
				
				status[this] = 2

				print "& " link " got complie-only " this  

				}

			print "& " link " got inter word " word  

			codes[word] = "0x0" 	

			}

		continue;

		}
	
	if (state == 1) {

		this = word;
	
		status[word] = 0

		codes[this] =  links[this] ", " links[":"]

		state = 2
			
		print "& " link " got name word " word 

		continue

		}

	if (state == 2) {

		if (word == ";") {

		
			codes[this] = codes[this] ", "  links[";"]

			state = 0;

			print "& " link " got semmi " 

			}

		else {

			codes[this] = codes[this] ", "  links[word] 

			print "& " link " got code word " word 
		
			}
	
		continue
	
		}

	print "& PANIC " " this " this " word " word " state " state 

	}

}

END {

	for (word in words) {

		print " link " links[word] " word " word " count ", words[word] "  state " status[word] ", codes ( " codes[word] " ) "
		
		}
}


