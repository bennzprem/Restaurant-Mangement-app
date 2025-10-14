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

        return True
    except ImportError:

        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", "qrcode[pil]==8.0"])

            return True
        except subprocess.CalledProcessError as e:

            return False

def main():
    """Main function to install dependencies and generate QR codes."""

    # Install qrcode library
    if not install_qrcode():

        return
    
    # Import and run the QR code generator
    try:
        from generate_table_qr_codes import main as generate_qr_codes
        generate_qr_codes()
    except ImportError as e:

    except Exception as e:

if __name__ == "__main__":
    main()
