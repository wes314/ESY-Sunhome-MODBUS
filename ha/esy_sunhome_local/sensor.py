import logging
import asyncio
from datetime import timedelta
from pymodbus.client import ModbusTcpClient
from homeassistant.helpers.entity import Entity
from homeassistant.helpers.update_coordinator import DataUpdateCoordinator, UpdateFailed, CoordinatorEntity
from homeassistant.components.sensor import SensorEntity
from .const import REGISTER_MAPPING, MODE_MAPPING, DOMAIN

_LOGGER = logging.getLogger(__name__)
SCAN_INTERVAL = timedelta(seconds=1)

class ESSensor(CoordinatorEntity, SensorEntity):
    """Representation of an ESY Sunhome sensor."""

    def __init__(self, coordinator, key, info=None):
        """Initialize the sensor.

        info is optional dictionary containing:
          - name: str
          - unit: str
          - scale: float
        """
        super().__init__(coordinator)
        self._key = key

        if info is None:
            info = {}
        self._name = info.get("name", f"ESY Sunhome {key}")
        self._unit = info.get("unit")
        self._scale = info.get("scale", 1)

        self._attr_name = self._name
        self._attr_unique_id = f"esy_sunhome_{key}"

    @property
    def native_value(self):
        val = self.coordinator.data.get(self._key)
        if val is None:
            return None

        # Example mapping for register 29
        if self._key == 29:
            from .const import MODE_MAPPING
            return MODE_MAPPING.get(val, "Unknown")

        return round(val * self._scale, 3)

    @property
    def unit_of_measurement(self):
        return self._unit

class ESYSunhomeLocalCoordinator(DataUpdateCoordinator):
    """Coordinator to fetch Modbus data."""

    def __init__(self, hass, config):
        self._host = config["host"]
        self._port = config["port"]
        self._slave_id = config["slave_id"]
        self._register_start = config.get("register_start", 1)
        self._register_count = config.get("register_count", 100)
        self._client = ModbusTcpClient(self._host, port=self._port)

        super().__init__(
            hass=hass,
            logger=_LOGGER,
            name="ESY Sunhome Local Coordinator",
            update_interval=SCAN_INTERVAL
        )

    async def _async_update_data(self):
        loop = asyncio.get_running_loop()
        try:
            # Reconnect if client not connected
            if not self._client.connected:
                _LOGGER.warning("Modbus client disconnected, attempting reconnect...")
                self._client.connect()

            rr = await loop.run_in_executor(
                None,
                lambda: self._client.read_input_registers(
                    address=self._register_start,
                    count=self._register_count,
                    slave=self._slave_id
                )
            )

            if rr is None or rr.isError():
                raise UpdateFailed(f"Modbus read error: {rr}")

            data = {}
            for i, val in enumerate(rr.registers):
                reg = self._register_start + i + 1

                # Handle signed registers
                if reg in [50, 91, 23, 26]:
                    if val >= 0x8000:
                        val -= 0x10000

                data[reg] = val

            return data

        except Exception as e:
            _LOGGER.warning(f"Modbus read failed: {e}, reconnecting client...")
            try:
                # Force reconnect next cycle
                self._client.close()
                await asyncio.sleep(2)
                self._client.connect()
            except Exception as ce:
                _LOGGER.error(f"Modbus reconnect failed: {ce}")
            raise UpdateFailed(f"Error reading Modbus: {e}")

import logging

_LOGGER = logging.getLogger(__name__)

async def async_setup_entry(hass, entry, async_add_entities):
    """Set up sensors from a config entry."""

    coordinator = hass.data[DOMAIN][entry.entry_id]

    _LOGGER.debug("async_setup_entry called! coordinator data: %s", coordinator.data)

    entities = []

    # Example: loop through your data points
    for key, value in REGISTER_MAPPING.items():
        info = REGISTER_MAPPING.get(key)  # dict with name/unit/scale
        if info is None:
            continue  # skip unmapped registers
        entity = ESSensor(coordinator, key, info)
        entities.append(entity)
        _LOGGER.debug("Preparing to add entity: %s", entity.name)

    if entities:
        async_add_entities(entities)
        _LOGGER.debug("Added %d entities", len(entities))
    else:
        _LOGGER.debug("No entities to add!")

