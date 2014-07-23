import sys
import getopt
import os

# define function for parsing input options
def main(argv):
	# set default values
	inputfolder = os.path.dirname(os.path.realpath(__file__))
	file_type = '.sql'
	outputfile = inputfolder + os.sep + 'output' + file_type
	help_text = "combine.py -i <inputfolder> -o <outputfile> -t <file_type>"
	
	
	try:
		# parse options/arguments passed to script
		# as called from command line
		opts, args = getopt.getopt(argv,"ht:i:o:")
	except getopt.GetoptError:
		# on error, print out help prompt and stop script
		print(help_text)
		sys.exit(2)
	
	
	# loop through options and extract input values
	for opt, arg in opts:
		if opt == '-h': # print help text
			print(help_text)
			# stop script execution
			sys.exit()
		elif opt == '-t': # set file type
			file_type = arg
		elif opt == "-i": # set input filename
			inputfolder = arg
		elif opt == "-o": # set output filename
			outputfile = arg
	
	# execute script to combine all files into one
	##########################################
	# remove log file, if exists
	try:
		os.remove(outputfile)
	except OSError:
		# ignore error if file not found
		pass

	# string to storing output
	results = str()
	
	# recursively walk through inputfolder
	for dirpath, dirnames, files in os.walk(inputfolder):
		for name in files:
			# check whether file type matches input
			if name.lower().endswith(file_type):
				# open each SQL file
				with open(os.path.join(dirpath, name), 'r') as file:
					# append contents to results string
					results += file.read() + '\n'
					file.close()

	# output full results to log file
	with open(outputfile, 'w') as logfile:
		logfile.write(results)
	##########################################
	
if __name__ == "__main__":
	main(sys.argv[1:])