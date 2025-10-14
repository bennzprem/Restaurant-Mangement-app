# ByteEat QR Code Generator

This tool generates QR codes for all tables in your restaurant database for the "Order from Table" feature.

## 🎯 What This Does

- Connects to your Supabase database
- Fetches all tables from the `tables` table
- Generates QR codes for each table in the format "TBL000" (e.g., TBL001, TBL002, etc.)
- Creates branded QR code images with restaurant information
- Saves all QR codes in a `qr_codes/` folder

## 📋 Prerequisites

1. **Database Setup**: Make sure you have tables in your `tables` table
2. **Python Dependencies**: The script will install required packages automatically
3. **Supabase Configuration**: Your `app.py` should have proper Supabase setup

## 🚀 Quick Start

### Option 1: Automatic Setup (Recommended)

**For Windows:**
```bash
cd backend
generate_qr_codes.bat
```

**For Linux/Mac:**
```bash
cd backend
chmod +x generate_qr_codes.sh
./generate_qr_codes.sh
```

### Option 2: Manual Setup

1. **Install Dependencies:**
   ```bash
   pip install qrcode[pil]==8.0
   ```

2. **Setup Tables (if needed):**
   ```bash
   python setup_tables_for_qr.py
   ```

3. **Generate QR Codes:**
   ```bash
   python generate_table_qr_codes.py
   ```

## 📁 Output Files

After running the script, you'll get:

```
qr_codes/
├── table_001_qr.png    # QR code for Table 1
├── table_002_qr.png    # QR code for Table 2
├── ...
├── table_020_qr.png    # QR code for Table 20
└── table_codes_summary.txt  # Summary of all table codes
```

## 🎨 QR Code Features

Each QR code includes:
- **Restaurant Branding**: "ByteEat" logo
- **Table Information**: Table number and code
- **Instructions**: "Scan to Order" and usage instructions
- **High Quality**: 400x500px images, perfect for printing

## 📱 QR Code Format

- **Table Code Format**: TBL000 (e.g., TBL001, TBL002, TBL020)
- **QR Code Content**: Just the table code (e.g., "TBL001")
- **Compatible with**: Your existing "Order from Table" feature

## 🖨️ Printing Instructions

1. **Print Size**: Recommended 4x5 inches (10x12.5 cm)
2. **Paper**: Use durable paper or laminate for restaurant use
3. **Placement**: Place on each table where customers can easily scan
4. **Testing**: Test scanning with your mobile app before placing

## 🔧 Customization

### Modify QR Code Design

Edit `generate_table_qr_codes.py` to customize:
- Restaurant name and branding
- Colors and styling
- Instructions text
- Image dimensions

### Change Table Code Format

To change from "TBL000" to another format:
1. Modify the `table_code` variable in `generate_qr_code()` function
2. Update your frontend to match the new format

## 🐛 Troubleshooting

### Common Issues

1. **Database Connection Error**
   - Check your Supabase configuration in `app.py`
   - Verify your database has a `tables` table

2. **No Tables Found**
   - Run `python setup_tables_for_qr.py` to create 20 tables
   - Check your database manually

3. **QR Code Generation Fails**
   - Install dependencies: `pip install qrcode[pil]==8.0`
   - Check file permissions in the output directory

4. **Import Errors**
   - Make sure `app.py` is in the same directory
   - Check your Python path and virtual environment

### Getting Help

If you encounter issues:
1. Check the console output for error messages
2. Verify your database connection
3. Ensure all dependencies are installed
4. Check file permissions

## 📊 Database Schema

The script expects a `tables` table with:
- `id` (uuid, primary key)
- `table_number` (integer)
- `capacity` (integer)
- `location_preference` (text, optional)

## 🔄 Integration with Your App

The generated QR codes work with your existing "Order from Table" feature:

1. **Customer scans QR code** → Gets table code (e.g., "TBL001")
2. **App processes table code** → Identifies the table
3. **Customer orders** → Order is associated with the table
4. **Kitchen receives order** → With table information

## 📈 Next Steps

After generating QR codes:

1. **Print and Place**: Print QR codes and place on tables
2. **Test Integration**: Test with your mobile app
3. **Train Staff**: Ensure staff knows how the system works
4. **Monitor Usage**: Track QR code scans and orders
5. **Update as Needed**: Regenerate QR codes if table numbers change

## 🎉 Success!

Once complete, customers can:
- Scan QR codes on tables
- Order directly from their table
- Enjoy a seamless dining experience
- Skip waiting for staff to take orders

---

**Need help?** Check the console output for detailed error messages and troubleshooting information.
