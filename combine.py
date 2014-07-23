import sys
import getopt
import os

# define function for parsing input options
def main(argv):
	# set default values
	inputfolder = os.path.dirname(os.path.realpath(__file__))
	file_type = ".sql"
	outputfile = inputfolder + os.sep + "output" + file_type
	help_text = """Description:
    Combines the text content of files in a directory and, recursively, its subdirectories
    into one output file. Only supports combining one file type at a time.
	Requires Python 3.x (NOT compatible with Python 2.x)

Usage:
    combine.py [-h] | [-i <input_folder>] [-o <output_file>] [-t <file_type>]

Options:
    -h, --help                              show this help message
    -i <path>, --input-folder <path>        the folder at which the recursive walk will begin
                                               (defaults to the folder in which the combine.py
                                               script is located)
    -o <path>, --output-file <path>         the name of the output file to which the combined
                                               text will be written (file name defaults to
                                               'output.sql', located in the same folder as the
                                               combine.py script)
    -t <extension>, --type <extension>      only files with a file type matching this input
                                               will be included in the combined output. the
                                               preceding dot (.) must be included in the input
                                               (defaults to '.sql')
"""
	
	
	try:
		# parse options/arguments passed to script
		# as called from command line
		opts, args = getopt.getopt(argv,"ht:i:o:",["help=","type=","input-folder=","output-file="])
	except getopt.GetoptError:
		# on error, print out help prompt and stop script
		print(help_text)
		sys.exit(2)
	
	
	# loop through options and extract input values
	for opt, arg in opts:
		if opt in ("-h", "--help"): # print help text
			print(help_text)
			# stop script execution
			sys.exit()
		elif opt in ("-t", "--type"): # set file type
			file_type = arg
		elif opt in ("-i", "--input-folder"): # set input filename
			inputfolder = arg
		elif opt in ("-o", "--output-file"): # set output filename
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
				with open(os.path.join(dirpath, name), "r") as file:
					# append contents to results string
					results += file.read() + "\n"
					file.close()

	# output full results to log file
	with open(outputfile, "w") as logfile:
		logfile.write(results)
	##########################################
	
if __name__ == "__main__":
	main(sys.argv[1:])