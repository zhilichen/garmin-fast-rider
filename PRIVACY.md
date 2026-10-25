# FastRider privacy notice

Last updated: October 24, 2026

FastRider is an open-source Connect IQ cycling data field. The developer does
not receive your ride, health, profile or location data through this app.

## Processing on your device

FastRider reads values provided by your Garmin device to display heart rate,
power, cadence, rear gear, speed, distance, ascent, timer and lap information.
It uses recent power samples and lap boundaries held in memory to draw the
power graph and calculate statistics. Gradient is estimated locally from
altitude and distance. When Garmin provides a named navigation destination,
FastRider may display the remaining distance.

The User Profile permission lets FastRider read your cycling FTP and heart-rate
zones. You can configure fallback FTP and maximum heart rate in app settings.
These settings are stored by Garmin's app-settings system.

## Sharing, storage and diagnostics

- The production app has no network communications, analytics, advertising,
  developer-operated server or separate user account.
- FastRider does not transmit the values above to the developer or third parties.
- The production app does not create its own activity files or developer logs.
  Garmin independently manages its activity recording and services.
- Graph samples and locally calculated statistics remain in app memory and are
  reset when the field is restarted or its activity state is reset. App settings
  persist until changed or removed through Garmin's app management.

Garmin's devices, Connect IQ Store, Connect and related services have their own
privacy notices. This notice describes FastRider's behavior, not Garmin's
independent processing.

## Support and changes

For questions, use the [FastRider issue tracker](https://github.com/zhilichen/garmin-fast-rider/issues).
Please avoid posting personal ride files, health readings, account credentials
or precise location data in public issues. If you choose to contact the developer
through GitHub, that information is submitted to the developer through GitHub,
not through FastRider or to Garmin; Garmin is not responsible for it. GitHub's
own privacy terms apply to its service.

Changes to FastRider's data handling will be reflected in this notice and the
public source repository.
