#!/usr/bin/env python3
"""
Install QR code dependencies and generate QR codes for all tables.
"""

import subprocess
import sys
import os

def install_qrcode():
    """Install the qrcode library if not already installed."""
    try:
        import qrcode
        print("✅ qrcode library is already installed")
        return True
    except ImportError:
        print("📦 Installing qrcode library...")
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", "qrcode[pil]==8.0"])
            print("✅ qrcode library installed successfully")
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ Failed to install qrcode library: {e}")
            return False

def main():
    """Main function to install dependencies and generate QR codes."""
    print("🚀 ByteEat QR Code Setup")
    print("=" * 40)
    
    # Install qrcode library
    if not install_qrcode():
        print("❌ Cannot proceed without qrcode library")
        return
    
    # Import and run the QR code generator
    try:
        from generate_table_qr_codes import main as generate_qr_codes
        generate_qr_codes()
    except ImportError as e:
        print(f"❌ Error importing QR code generator: {e}")
        print("Make sure generate_table_qr_codes.py is in the same directory")
    except Exception as e:
        print(f"❌ Error generating QR codes: {e}")

if __name__ == "__main__":
    main()
