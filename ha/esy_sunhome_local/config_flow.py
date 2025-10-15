import voluptuous as vol
from homeassistant import config_entries
from .const import DOMAIN, DEFAULT_CONFIG

class ESYSunhomeLocalFlowHandler(config_entries.ConfigFlow, domain=DOMAIN):
    """Config flow for ESY Sunhome Local."""

    VERSION = 1

    async def async_step_user(self, user_input=None):
        if user_input is not None:
            return self.async_create_entry(title="ESY Sunhome Local", data=user_input)

        schema = vol.Schema({
            vol.Required("host", default=DEFAULT_CONFIG["host"]): str,
            vol.Required("port", default=DEFAULT_CONFIG["port"]): int,
            vol.Required("slave_id", default=DEFAULT_CONFIG["slave_id"]): int,
        })
        return self.async_show_form(step_id="user", data_schema=schema)

