import logging
import sys
import time
from openrgb import OpenRGBClient
import win32api
import win32con
import win32gui
import ctypes
from ctypes import wintypes

# --- ctypes definitions for power notifications ---
class GUID(ctypes.Structure):
    _fields_ = [
        ("Data1", wintypes.DWORD),
        ("Data2", wintypes.WORD),
        ("Data3", wintypes.WORD),
        ("Data4", ctypes.c_ubyte * 8)
    ]
    def __eq__(self, other):
        return self.Data1 == other.Data1 and \
               self.Data2 == other.Data2 and \
               self.Data3 == other.Data3 and \
               self.Data4[:] == other.Data4[:]

class POWERBROADCAST_SETTING(ctypes.Structure):
    _fields_ = [("PowerSetting", GUID),
                ("DataLength", wintypes.DWORD),
                ("Data", ctypes.c_byte * 1)]

PPOWERBROADCAST_SETTING = ctypes.POINTER(POWERBROADCAST_SETTING)
GUID_MONITOR_POWER_ON = GUID(0x02731015, 0x4510, 0x4526,
                             (ctypes.c_ubyte * 8)(0x99, 0xE6, 0xE5, 0xA1, 0x7E, 0xBD, 0x1A, 0xEA))
PBT_POWERSETTINGCHANGE = 0x8013
# --- End of ctypes definitions ---

# --- Configuration ---
# OpenRGB Connection Parameters
OPENRGB_HOST = 'localhost'
OPENRGB_PORT = 6742
CLIENT_NAME = 'DisplayRGBSync'

# Profile Names
ACTIVE_PROFILE_NAME = "jwadow"
OFF_PROFILE_NAME = "off"

# Logging Settings
# Level: DEBUG, INFO, WARNING, ERROR, CRITICAL
LOG_LEVEL = "INFO"
# --------------------

# --- Global Variables ---
client = None
last_active_profile = ACTIVE_PROFILE_NAME

# --- Logging Setup ---
def setup_logging(log_level_str):
    """Configures logging to the console."""
    log_level = getattr(logging, log_level_str.upper(), logging.INFO)
    
    # Log output to console (stdout)
    handler = logging.StreamHandler(sys.stdout)
    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
    handler.setFormatter(formatter)
    
    logger = logging.getLogger()
    logger.setLevel(log_level)
    logger.addHandler(handler)

# --- OpenRGB Functions ---
def connect_openrgb():
    """
    Establishes a connection to the OpenRGB SDK server.
    Retries on failure.
    """
    global client
    while True:
        try:
            logging.info(f"Attempting to connect to OpenRGB SDK at {OPENRGB_HOST}:{OPENRGB_PORT}")
            client = OpenRGBClient(OPENRGB_HOST, OPENRGB_PORT, CLIENT_NAME)
            if client.devices:
                logging.info("Successfully connected to OpenRGB SDK.")
                return True
        except Exception as e:
            logging.error(f"Failed to connect to OpenRGB: {e}. Retrying in 10 seconds.")
            time.sleep(10)

def load_profile(profile_name):
    """
    Loads the specified OpenRGB profile, handling reconnections.
    If the connection is lost, it will attempt to reconnect and retry.
    """
    try:
        logging.info(f"Attempting to load profile: {profile_name}")
        # The client object might be None or the connection might be stale.
        # Either way, trying to use it will raise an exception if it's not working.
        client.load_profile(profile_name)
        logging.info(f"Successfully loaded profile: {profile_name}")
    except Exception as e:
        logging.warning(f"Could not load profile ({e}). Assuming connection lost, attempting to reconnect.")
        if connect_openrgb():  # This function blocks until a connection is made.
            logging.info("Reconnected to OpenRGB. Retrying profile load.")
            try:
                client.load_profile(profile_name)
                logging.info(f"Successfully loaded profile after reconnect: {profile_name}")
            except Exception as e2:
                logging.error(f"Failed to load profile on second attempt: {e2}")

# --- Windows Event Handling Logic ---
def wnd_proc(hwnd, msg, w_param, l_param):
    """Window message handler."""
    global last_active_profile

    if msg == win32con.WM_POWERBROADCAST:
        if w_param == win32con.PBT_APMSUSPEND:
            logging.info("System is going to sleep. Loading 'OFF' profile.")
            load_profile(OFF_PROFILE_NAME)
        elif w_param == win32con.PBT_APMRESUMEAUTOMATIC:
            logging.info("System resumed from sleep. Restoring active profile.")
            load_profile(last_active_profile)
        elif w_param == PBT_POWERSETTINGCHANGE:
            # l_param is a pointer to a POWERBROADCAST_SETTING structure.
            power_info = ctypes.cast(l_param, PPOWERBROADCAST_SETTING).contents
            if power_info.PowerSetting == GUID_MONITOR_POWER_ON:
                # Data is a single byte. Based on user feedback: 0=Off, 1=On.
                power_data = power_info.Data[0]
                logging.debug(f"Received monitor power state event. Raw data: {power_data}")

                if power_data == 1: # Assuming 1 is ON
                    logging.info("Monitors turned on. Restoring active profile.")
                    load_profile(last_active_profile)
                elif power_data == 0: # User reported 0 is OFF
                    logging.info("Monitors turned off. Loading 'OFF' profile.")
                    load_profile(OFF_PROFILE_NAME)

    return win32gui.DefWindowProc(hwnd, msg, w_param, l_param)

def main():
    """Main application function."""
    setup_logging(LOG_LEVEL)
    logging.info("Starting DisplayRGBSync.")

    # Restore active profile on startup.
    # This first call will also handle the initial connection to the OpenRGB server.
    load_profile(ACTIVE_PROFILE_NAME)

    # Create a message-only window to receive system messages
    wc = win32gui.WNDCLASS()
    wc.lpszClassName = 'DisplayRGBSync_Message_Window'
    wc.lpfnWndProc = wnd_proc
    class_atom = win32gui.RegisterClass(wc)
    
    hwnd = win32gui.CreateWindow(class_atom, 'DisplayRGBSync Hidden Window', 0, 0, 0, 0, 0, win32con.HWND_MESSAGE, 0, 0, None)
    
    if not hwnd:
        logging.critical("Failed to create message-only window.")
        sys.exit(1)

    # Register for monitor power setting notifications
    try:
        user32 = ctypes.windll.user32
        h_power_notify = user32.RegisterPowerSettingNotification(wintypes.HANDLE(hwnd), ctypes.byref(GUID_MONITOR_POWER_ON), win32con.DEVICE_NOTIFY_WINDOW_HANDLE)
        if h_power_notify:
            logging.info("Successfully registered for monitor power state notifications.")
        else:
            logging.error(f"RegisterPowerSettingNotification failed with error code: {ctypes.get_last_error()}")
    except Exception as e:
        logging.critical(f"Critical error while registering for monitor power state notifications: {e}")
        sys.exit(1)
    
    logging.info("Application is running in the background and monitoring power state.")
    
    # Message pump loop
    win32gui.PumpMessages()

if __name__ == '__main__':
    main()