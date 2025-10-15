"""ESY Sunhome Local integration."""

from .const import DOMAIN
from .sensor import ESYSunhomeLocalCoordinator
import logging

_LOGGER = logging.getLogger(__name__)

async def async_setup(hass, config):
    """Optional YAML setup (empty)."""
    _LOGGER.debug("esy_sunhome_local __init__.py -> async_setup called!")
    return True

async def async_setup_entry(hass, entry):
    """Set up from a config entry."""
    _LOGGER.debug("esy_sunhome_local __init__.py -> async_setup_entry called!")
    
    hass.data.setdefault(DOMAIN, {})

    config = entry.data
    coordinator = ESYSunhomeLocalCoordinator(hass, config)
    await coordinator.async_refresh()
    hass.data.setdefault(DOMAIN, {})[entry.entry_id] = coordinator

    # Forward setup to sensor platform
    await hass.config_entries.async_forward_entry_setups(entry, ["sensor"])

    return True


