@echo off
echo ========================================
echo ByteEat QR Code Generator
echo ========================================
echo.

echo Installing QR code dependencies...
python -m pip install qrcode[pil]==8.0

echo.
echo Generating QR codes for all tables...
python generate_table_qr_codes.py

echo.
echo ========================================
echo QR Code generation complete!
echo Check the 'qr_codes' folder for generated images.
echo ========================================
pause
