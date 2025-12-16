# Batch CIA 3DS Decryptor (Enhanced Edition)

*Fork based on original work by [matiffeder](https://github.com/matiffeder/3DS-stuff)*

An advanced and refined version of the popular batch script for automatic Nintendo 3DS ROM decryption.
This fork optimizes the workflow for emulator users, adding support for new formats, cleaner file management, and detailed compression statistics.

## ⚠️ Disclaimer

This script is provided "as is" for educational and personal backup purposes. Ensure you legally own the games you intend to decrypt. The author is not responsible for any misuse of this tool.

## 🚀 New Features

Compared to the original script, this version includes:

* **Dedicated Output Folder**: All processed files are automatically saved in a `decrypted/` subfolder, keeping the root directory clean.
* **Native `.cci` Support**: Recognizes, decrypts, and preserves the extension of `.cci` files (often used for cartridge dumps).
* **Compression (Trimming) Statistics**:
    * Calculates and displays real-time (in green) how much space was saved by removing dummy/encrypted data for each game.
    * Shows reduction in both percentage and MB.
    * Calculates a **Global Total** of disk space saved at the end of the batch process (in cyan).
* **Clean File Names**: Automatically removes unnecessary suffixes like `-decrypted` or `-decfirst`. The output file will have the same clean name as the input file.
* **Special Character Support**: Fixed a critical bug that caused the script to crash with filenames containing apostrophes (e.g., *Luigi's Mansion*) or parentheses, thanks to improved PowerShell integration.
* **Smart Logic for CIAs**:
    * `.cia` **Games** are converted to `.cci` (File > Load File in Citra).
    * `.cia` **Updates** and **DLCs** remain `.cia` (File > Install CIA in Citra).

## 🎮 How to Use

1.  Download or clone this repository.
2.  Place your encrypted files (`.3ds`, `.cia`, `.cci`) in the script's root folder.
3.  Run the `.bat` file.
4.  Wait for the operations to complete.
5.  You will find your ready-to-use files in the `decrypted/` folder.

## 🔄 Conversion Table

Here is how files are transformed:

| Input File | Content Type | Output File (in `decrypted/` folder) | Usage on Citra |
| :--- | :--- | :--- | :--- |
| **Game.3ds** | Cartridge | `Game.3ds` | File > Load File... |
| **Game.cci** | Cartridge | `Game.cci` | File > Load File... |
| **Game.cia** | eShop Game | `Game.cci` | File > Load File... |
| **Update.cia** | Patch v1.X | `Update (Patch).cia` | File > Install CIA... |
| **DLC.cia** | Extra Content | `DLC (DLC).cia` | File > Install CIA... |

## 📊 Output Example

```text
Processing: Luigi's Mansion 2
   -> Reduced by 15.40% (-250.50 MB)

Processing: Super Mario 3D Land (Patch)
   -> Reduced by 2.10% (-5.00 MB)

======================================================
 FINISHED!
 Files are located in the "decrypted" folder.

 ------------------------------------------------
 GLOBAL BATCH STATISTICS:
 Total Space Saved: -255.50 MB
 ------------------------------------------------
======================================================
```
