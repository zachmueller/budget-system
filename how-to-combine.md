# How To Use `combine.py`
 - use `python combine.py -h` to view the help message
 - written using Python 3.4 (NOT compatible with Python 2.x)

## Example Usage
 - Setup:
  - the budget-system repo is located at `C:\Users\zach\Documents\GitHub\budget-system\` on my laptop
  - the `combine.py` script sits directly in that folder
  - Python 3.4 installed with `python` command accessible via the system's PATH variable

1. Move to `budget-system` parent directory
```PowerShell
cd C:\Users\zach\Documents\GitHub\budget-system
```

2. Execute the `combine.py` script
 - `-i` is the Input Folder, where the script will recursively search for files
 - `-o` is the Output File, where the combined script will be stored
 - `-t` is the File Type to be searched for

 ```PowerShell
python combine.py -i 'C:\Users\zach\Documents\GitHub\budget-system' -o 'C:\Users\zach\Documents\GitHub\budget-system\output.sql' -t '.sql'
 ```
