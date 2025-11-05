# OpenRGB Scripts

This repository contains a collection of Python scripts for automating and extending the functionality of [OpenRGB](https://openrgb.org/) on the Windows operating system.

The project is built on a portable, isolated Python environment, which allows running scripts without installing dependencies into the main system.

## Installation and Usage

1.  **Clone or download the repository.**

2.  **Run `setup.bat`**. This script will automatically perform all necessary setup steps:
    *   If a local Python environment is not found, it will download a portable version of Python.
    *   It will configure the environment for use with external packages.
    *   It will install `pip` (if not already present) and all dependencies from `requirements.txt`.
    **This step only needs to be performed once.** An internet connection is required for the first run.

3.  **Configure the OpenRGB server to start.**
    The scripts require a running OpenRGB SDK server. It is recommended to configure it to start automatically:
    *   Find the OpenRGB shortcut.
    *   Open its properties.
    *   In the "Target" field, after the path to `OpenRGB.exe`, add the flags `--server --gui`.
    *   Example: `"C:\Program Files\OpenRGB\OpenRGB.exe" --server --gui`

4.  **Configure the scripts.**
    Before running, you may need to configure some scripts (e.g., set your OpenRGB profile names). See the "Available Scripts" section below for details on each script.

5.  **Run the script.**
    To run the main script in the background, use:
    ```batch
    run_sync.bat
    ```
    By default, this file is configured to run `DisplayRGBSync.pyw`.

6.  **Set up autostart.**
    Now, to have the script start automatically every time you log in, run:
    ```batch
    setup_autostart.bat
    ```
    This script will create a shortcut in the Windows startup folder.

---

## Available Scripts

### 1. DisplayRGBSync

**Purpose:**
Synchronizes OpenRGB lighting profiles with the power state of monitors and the system's sleep/wake mode. The script automatically applies an "off" profile when the monitors turn off or the system goes to sleep, and restores your active profile upon waking.

**Configuration:**
All settings are configured directly in the `DisplayRGBSync.pyw` file.

1.  Open `DisplayRGBSync.pyw` in a text editor.
2.  Change the values of `ACTIVE_PROFILE_NAME` and `OFF_PROFILE_NAME` to match the names of your profiles in OpenRGB.
3.  If necessary, change `OPENRGB_HOST` and `OPENRGB_PORT`.

```python
# --- Configuration ---
# Profile Names
ACTIVE_PROFILE_NAME = "jwadow" # Your main profile
OFF_PROFILE_NAME = "off"       # Your profile to "turn off" the lighting
```

---

## Architecture and Infrastructure

This section is for developers and those who want to understand how the project is structured.

-   **`setup.bat`**: The initial setup script to prepare the environment. It's idempotent and can be run multiple times.
-   **`run_sync.bat`**: A universal batch file for running the target script (`.pyw`) in the background.
-   **`setup_autostart.bat`**: A batch file for creating a shortcut in the Windows startup folder.
-   **`requirements.txt`**: A file listing all Python dependencies required for the scripts to work.
