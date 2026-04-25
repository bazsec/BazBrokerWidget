# BazBrokerWidget Changelog

## 001 - Initial release
- Bridges every registered LibDataBroker-1.1 feed into BazWidgetDrawers as its own dockable widget
- Live updates on `text`/`value`/`icon`/`label` attribute changes
- Late-registering feeds picked up via `LibDataBroker_DataObjectCreated`
- Click forwards to the feed's `OnClick`; hover forwards to `OnTooltipShow`/`OnEnter`/`OnLeave`
- `/bbw list` slash command to inspect every currently registered feed
