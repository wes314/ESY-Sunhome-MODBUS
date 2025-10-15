DOMAIN = "esy_sunhome_local"

DEFAULT_CONFIG = {
    "host": "192.168.3.17",
    "port": 4196,
    "slave_id": 1,
    "register_start": 1,
    "register_count": 100
}

REGISTER_MAPPING = {
    33: {"name": "Battery SOC", "unit": "%", "scale": 1},
    32: {"name": "Mode Power", "unit": "W", "scale": 1},
    29: {"name": "Battery Mode", "unit": None, "scale": 1},
    50: {"name": "Grid Power", "unit": "W", "scale": 1},
    91: {"name": "Load Power", "unit": "W", "scale": 1},
    23: {"name": "PV1 Power", "unit": "W", "scale": 1},
    26: {"name": "PV2 Power", "unit": "W", "scale": 1},
    43: {"name": "Grid AC Volts", "unit": "V", "scale": 0.1},
    40: {"name": "Freq HZ1", "unit": "Hz", "scale": 0.01},
    55: {"name": "Freq HZ2", "unit": "Hz", "scale": 0.01},
    58: {"name": "Ext PV AC Volts?", "unit": "V", "scale": 0.1},
    76: {"name": "Int PV AC Volts?", "unit": "V", "scale": 0.1},
}

MODE_MAPPING = {
    0: "Unknown",
    1: "Charging",
    2: "Charge topping",
    3: "Unknown",
    4: "Full",
    5: "Discharging",
}

