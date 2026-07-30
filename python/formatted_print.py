# File Name :formatted_print.py
"""
Date        : 12/30/2020
Author      : tphilip
Description : Formats the print calls. 
Automatically aligns the displayed text by calculating the length of the longest "Description" and adjusts the alignment accordingly for all the other "Descriptions"
Output      : 
Name of the person : James
Age                : 34
Location           : Europe
"""

# Pre-requisite : Python 3.6+

# STEPS
# Step 1  : Import => from fomatted_print import pretty_print
# Step 2  : Declare the variable => print_input = []
# Step 3  : Append the "Description" and "Value" to print_input[]
# Step 3a : print_input.append((<Description>, <Value>))
# Step 3b : Repeat Step 3a, wherever inside your code where you need formatted print.
# Step 4  : Call the function: pretty_print(print_input)

# GLOBAL VARIABLES
FILENAME = "formatted_print.py"


def pretty_print(passed_input):
    length_description = 0

    for description, *_ in passed_input:
        if length_description < len(description):
            length_description = len(description)

    for description, value, *_ in passed_input:
        description_buffer = [' '] * length_description

        for index, letter in enumerate(description):
            description_buffer[index] = letter

        final_description = ''.join(map(str, description_buffer))
        print(f"{final_description} : {value}")


# This section is added to show the usage of "pretty_print()"
if __name__ == "__main__":
    print(f"{FILENAME} is called directly. Please use import instead.")
    # FUNCTION CALL
    print_input: list = []
    text01 = "Name of the person"
    value01 = "James"
    print_input.append((text01, value01))
    print_input.append(("Age", 34))
    print_input.append(("Location", "Europe"))
    pretty_print(print_input)
