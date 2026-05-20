#!/usr/bin/env python3
"""
ODX8 USB Creator
Creates a bootable USB drive with ODX8 Operating System
"""

import sys
import os
import subprocess
import platform

def print_banner():
    print("=" * 60)
    print("  ODX8 USB Creator")
    print("  Create Bootable USB Drive")
    print("=" * 60)
    print()

def check_admin():
    """Check if running with administrator privileges"""
    if platform.system() == 'Windows':
        try:
            import ctypes
            return ctypes.windll.shell32.IsUserAnAdmin()
        except:
            return False
    else:
        return os.geteuid() == 0

def list_drives():
    """List available drives"""
    print("Available drives:")
    print()
    
    if platform.system() == 'Windows':
        # List drives on Windows
        import string
        from ctypes import windll
        
        drives = []
        bitmask = windll.kernel32.GetLogicalDrives()
        for letter in string.ascii_uppercase:
            if bitmask & 1:
                drive = f"{letter}:"
                drive_type = windll.kernel32.GetDriveTypeW(drive + "\\")
                if drive_type == 2:  # Removable drive
                    drives.append(drive)
                    print(f"  {drive} (Removable)")
            bitmask >>= 1
        
        return drives
    else:
        # List drives on Linux
        try:
            result = subprocess.run(['lsblk', '-d', '-n', '-o', 'NAME,SIZE,TYPE'],
                                  capture_output=True, text=True)
            print(result.stdout)
            return []
        except:
            print("ERROR: Could not list drives")
            return []

def create_usb(image_file, target_drive):
    """Write image to USB drive"""
    print(f"\nWriting {image_file} to {target_drive}...")
    print("WARNING: This will erase all data on the target drive!")
    print()
    
    confirm = input("Type 'YES' to continue: ")
    if confirm != 'YES':
        print("Cancelled.")
        return False
    
    if platform.system() == 'Windows':
        # Use dd for Windows (if available) or recommend Rufus
        print("\nOn Windows, please use one of these tools:")
        print("1. Rufus: https://rufus.ie/")
        print("2. Win32 Disk Imager: https://sourceforge.net/projects/win32diskimager/")
        print(f"\nSelect the image file: {os.path.abspath(image_file)}")
        print(f"Select the target drive: {target_drive}")
        return False
    else:
        # Use dd on Linux
        try:
            cmd = ['sudo', 'dd', f'if={image_file}', f'of={target_drive}',
                   'bs=4M', 'status=progress', 'conv=fsync']
            subprocess.run(cmd, check=True)
            print("\nUSB drive created successfully!")
            return True
        except subprocess.CalledProcessError:
            print("\nERROR: Failed to write to USB drive")
            return False
        except Exception as e:
            print(f"\nERROR: {e}")
            return False

def main():
    print_banner()
    
    # Check for image file
    image_file = 'odx8.iso'
    if not os.path.exists(image_file):
        print(f"ERROR: {image_file} not found!")
        print("Please run build-odx8.bat first to create the ISO image.")
        sys.exit(1)
    
    print(f"Image file: {image_file}")
    print(f"Image size: {os.path.getsize(image_file) / 1024 / 1024:.2f} MB")
    print()
    
    # Check admin privileges
    if not check_admin():
        print("WARNING: Not running as administrator/root")
        print("You may need elevated privileges to write to USB drives.")
        print()
    
    # List drives
    drives = list_drives()
    
    if platform.system() == 'Windows':
        print("\n" + "=" * 60)
        print("WINDOWS INSTRUCTIONS:")
        print("=" * 60)
        print("\n1. Download Rufus from: https://rufus.ie/")
        print("2. Run Rufus as Administrator")
        print(f"3. Select your USB drive")
        print(f"4. Select the image: {os.path.abspath(image_file)}")
        print("5. Click START")
        print("\nAlternatively, use Win32 Disk Imager or similar tool.")
    else:
        print("\n" + "=" * 60)
        print("LINUX INSTRUCTIONS:")
        print("=" * 60)
        print("\nTo create bootable USB:")
        print(f"  sudo dd if={image_file} of=/dev/sdX bs=4M status=progress conv=fsync")
        print("\nReplace /dev/sdX with your USB drive (e.g., /dev/sdb)")
        print("WARNING: Double-check the device name to avoid data loss!")
        print("\nOr use this script:")
        print(f"  sudo python3 {sys.argv[0]} /dev/sdX")
        
        if len(sys.argv) > 1:
            target = sys.argv[1]
            create_usb(image_file, target)

if __name__ == '__main__':
    main()
