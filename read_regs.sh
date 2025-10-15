#!/usr/bin/env python3
import time
import os
import logging
from pymodbus.client import ModbusTcpClient
from pymodbus.exceptions import ModbusException

# =============================
# Debug logging setup
#logging.basicConfig(
#    level=logging.DEBUG,
#    format="%(asctime)s [%(levelname)s] %(message)s",
#)

# =============================
# Configuration
DELAY = 1
IP = "192.168.3.17"
PORT = 4196
SLAVE_ID = 1
REGISTER_START = 0
REGISTER_COUNT = 100

# =============================
# Register name mapping
register_names = {
    33: "Battery SOC (%)",
    50: "Grid Power (W)",
    91: "Load Power (W)",
    23: "PV1 Power (W)",
    26: "PV2 Power (W)",
    29: "Mode",
    32: "Mode power",
    43: "Grid AC Volts",
    40: "Freq HZ",
    55: "Freq HZ",
    58: "Ext PV AC Volts?",
    76: "Int PV AC Volts?",
}

# Registers that need scaling
register_scale = {
    40: 0.01,
    55: 0.01,
    43: 0.1,
    58: 0.1,
    64: 0.01,
    67: 0.01,
    72: 0.001,
    76: 0.1,
}

# Register value translations
register_values = {
    (29, 0): "Unknown",
    (29, 1): "Charging",
    (29, 2): "Charge topping",
    (29, 3): "Unknown",
    (29, 4): "Full",
    (29, 5): "Discharging",
}

# =============================
def clear():
    os.system("clear" if os.name == "posix" else "cls")


def poll_modbus(client):
    """Read Modbus registers and return dict of register:value"""
    try:
        rr = client.read_input_registers(address=REGISTER_START, count=REGISTER_COUNT, device_id=1)
        if rr.isError():
            logging.error(f"Modbus error: {rr}")
            return {}
        return {REGISTER_START + i + 1: val for i, val in enumerate(rr.registers)}
    except ModbusException as e:
        logging.error(f"Modbus exception: {e}")
    except Exception as e:
        logging.error(f"Exception: {e}")
    return {}


def format_value(reg, val):
    """Apply scaling and translation"""
    if reg in register_scale:
        val = round(val * register_scale[reg], 3)
    text = f"{val}"
    if (reg, val) in register_values:
        text += f" ({register_values[(reg, val)]})"
    return text


def main():
    client = ModbusTcpClient(IP, port=PORT)
    if not client.connect():
        logging.error(f"Failed to connect to {IP}:{PORT}")
        return

    try:
        while True:
            regs = poll_modbus(client)
            clear()
            print(f"Modbus Register Monitor - {time.strftime('%H:%M:%S')}")
            print("===============================================")
            print(f"{'Reg':<6} {'Name':<25} {'Value':<20}")
            print("===============================================")

            mode_val = mode_power = soc_val = None
            mode_desc = ""

            for reg, val in regs.items():
                if reg in register_names:
                    display_val = format_value(reg, val)
                    print(f"{reg:<6} {register_names[reg]:<25} {display_val}")
                    if reg == 29:
                        mode_val = val
                        mode_desc = register_values.get((reg, val), "")
                    elif reg == 32:
                        mode_power = val
                    elif reg == 33:
                        soc_val = val

            print("\n-----------------------------------------------")
            print(
                f"Battery {mode_desc or 'Unknown'}: "
                f"{soc_val or '?'}% {mode_power or '?'}W"
            )
            print("-----------------------------------------------")
            time.sleep(DELAY)

    except KeyboardInterrupt:
        print("\nExiting...")
    finally:
        client.close()


if __name__ == "__main__":
    main()

