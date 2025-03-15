import sys
import os

def parse_figlet_font(text, font_file):
    # Check if the file has a .flf extension
    if not font_file.endswith(".flf"):
        raise ValueError("Invalid file type. Must be a .flf file.")
    
    with open(font_file, "r", encoding="utf-8") as file:
        lines = file.readlines()
    
    # Check if it's a valid Figlet font file
    if not lines[0].startswith("flf2a$"):
        raise ValueError("Invalid Figlet font file: Missing header.")
    
    # Extract header variables
    header_parts = lines[0].split()
    hard_blank = header_parts[0][-1]  # Character used as a placeholder
    height = int(header_parts[1])  # Number of lines per character
    baseline = int(header_parts[2])
    max_length = int(header_parts[3])
    old_layout = int(header_parts[4])
    comment_lines = int(header_parts[5])
    
    # Extract ASCII art definitions
    ascii_art = {}
    start_index = 1 + comment_lines  # Position where characters start
    
    for i in range(32, 127):  # Standard ASCII range
        char = chr(i)
        char_art = lines[start_index:start_index + height]
        ascii_art[char] = [line.rstrip("\n").replace(hard_blank, " ").replace("@", "") for line in char_art]
        start_index += height
    
    # Convert text to ASCII art
    output_lines = ["" for _ in range(height)]
    for char in text:
        if char in ascii_art:
            for i in range(height):
                output_lines[i] += ascii_art[char][i] + "  "  # Add spacing
        else:
            for i in range(height):
                output_lines[i] += " " * max_length + "  "
    
    return "\n".join(output_lines)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <text> <figlet_font.flf>")
        sys.exit(1)
    
    input_text = sys.argv[1]
    font_path = sys.argv[2]
    
    try:
        output = parse_figlet_font(input_text, font_path)
        print(output)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
