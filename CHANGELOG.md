# 2.0.0

- BREAKING CHANGE: Enable Meta to track User Data: a select instead of checkbox. After update: double check your settings.
- updated to newest FB template:
  - renamed function name
  - added referrer
- added automated process of reposted hits
- Added more parameter mappings
- Multi-Pixel Support: Updated the template to accept comma-separated lists for Pixel ID and API Access Token. The tag now loops through these lists and sends individual server-side requests for each pair.
- Enhanced Parameter Mapping: Added logic to automatically set content_type = "product" if items/contents are present but the parameter is missing.
- UI Updates: Refreshed display names and help text to clarify multi-pixel usage and other.

# 1.6.0

- added a checkbox to allow user data collection
- added user_email and user_phone_number to customEventMapping
- template automatically grabs user_data.sha256_email_address and user_data.sha256_phone_number

# 1.5.0

- added event id to FB standard parameters
- FIX: custom parameter mapping did not work before.

# 1.4.0

- update to newest Facebook template: 0.0.9 (Sept 5, 2023)
- custom server cookie remove, as FB now covering this.
- gave more IP anonymisation options
- added user_agent to mapping. So you can override it now if you wish

# 1.3.0

- server manged cookies
- ip anonymasation

# 1.2.0

- added user_details to FB_PARAMS_MAPPINGS

# 1.1.0

- added IP anonymization as option

# 1.0.0

- initial Version
