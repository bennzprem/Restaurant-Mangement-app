#!/usr/bin/env python3
"""
QR Code Generator for Restaurant Tables
Generates QR codes for all tables in the database for the "Order from Table" feature.
"""

import os
import sys
import qrcode
from PIL import Image, ImageDraw, ImageFont
import requests
from datetime import datetime

# Add the current directory to Python path to import from app.py
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Import Supabase configuration from app.py
try:
    from app_refactored import supabase, SUPABASE_URL, SUPABASE_KEY
except ImportError:

    sys.exit(1)

def generate_qr_code(table_number, output_dir="qr_codes"):
    """
    Generate a QR code for a specific table number.
    
    Args:
        table_number (int): The table number
        output_dir (str): Directory to save the QR code images
    
    Returns:
        str: Path to the generated QR code image
    """
    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    # Create table code in the format "TBL000"
    table_code = f"TBL{table_number:03d}"
    
    # Create QR code
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    
    # Add data to QR code
    qr.add_data(table_code)
    qr.make(fit=True)
    
    # Create QR code image
    qr_image = qr.make_image(fill_color="black", back_color="white")
    
    # Resize the image to make it larger and more readable
    qr_image = qr_image.resize((300, 300), Image.Resampling.LANCZOS)
    
    # Create a larger canvas with branding
    canvas_width = 400
    canvas_height = 500
    canvas = Image.new('RGB', (canvas_width, canvas_height), 'white')
    
    # Paste QR code in the center
    qr_x = (canvas_width - 300) // 2
    qr_y = 50
    canvas.paste(qr_image, (qr_x, qr_y))
    
    # Add text using PIL's default font
    draw = ImageDraw.Draw(canvas)
    
    try:
        # Try to use a better font if available
        font_large = ImageFont.truetype("arial.ttf", 24)
        font_medium = ImageFont.truetype("arial.ttf", 18)
        font_small = ImageFont.truetype("arial.ttf", 14)
    except:
        # Fallback to default font
        font_large = ImageFont.load_default()
        font_medium = ImageFont.load_default()
        font_small = ImageFont.load_default()
    
    # Add restaurant branding
    draw.text((canvas_width//2, 20), "ByteEat", fill="black", font=font_large, anchor="mm")
    
    # Add table information
    draw.text((canvas_width//2, 370), f"Table {table_number}", fill="black", font=font_medium, anchor="mm")
    draw.text((canvas_width//2, 395), table_code, fill="green", font=font_medium, anchor="mm")
    draw.text((canvas_width//2, 420), "Scan to Order", fill="gray", font=font_small, anchor="mm")
    
    # Add instructions
    draw.text((canvas_width//2, 450), "Point camera at QR code", fill="gray", font=font_small, anchor="mm")
    draw.text((canvas_width//2, 470), "to start ordering", fill="gray", font=font_small, anchor="mm")
    
    # Save the image
    filename = f"table_{table_number:03d}_qr.png"
    filepath = os.path.join(output_dir, filename)
    canvas.save(filepath)
    
    return filepath

def fetch_tables_from_database():
    """
    Fetch all tables from the database.
    
    Returns:
        list: List of table numbers
    """
    try:

        # Fetch all tables from the database
        response = supabase.table('tables').select('table_number').order('table_number').execute()
        
        if not response.data:

            return []
        
        table_numbers = [table['table_number'] for table in response.data]
        
        return table_numbers
        
    except Exception as e:

        return []

def create_table_codes_summary(table_numbers, output_dir="qr_codes"):
    """
    Create a summary file with all table codes.
    
    Args:
        table_numbers (list): List of table numbers
        output_dir (str): Directory where QR codes are saved
    """
    summary_file = os.path.join(output_dir, "table_codes_summary.txt")
    
    with open(summary_file, 'w') as f:
        f.write("ByteEat - Table QR Codes Summary\n")
        f.write("=" * 40 + "\n")
        f.write(f"Generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"Total tables: {len(table_numbers)}\n\n")
        
        f.write("Table Codes:\n")
        f.write("-" * 20 + "\n")
        
        for table_num in sorted(table_numbers):
            table_code = f"TBL{table_num:03d}"
            f.write(f"Table {table_num:2d}: {table_code}\n")
        
        f.write("\nInstructions:\n")
        f.write("-" * 20 + "\n")
        f.write("1. Print each QR code image\n")
        f.write("2. Place QR codes on corresponding tables\n")
        f.write("3. Customers can scan to order directly from table\n")
        f.write("4. QR codes contain table codes in format TBL000\n")

def main():
    """
    Main function to generate QR codes for all tables.
    """

    # Fetch tables from database
    table_numbers = fetch_tables_from_database()
    
    if not table_numbers:

        return
    
    # Generate QR codes for each table
    generated_files = []
    for table_num in table_numbers:
        try:
            filepath = generate_qr_code(table_num)
            generated_files.append(filepath)
        except Exception as e:

    # Create summary file
    create_table_codes_summary(table_numbers)

if __name__ == "__main__":
    main()
