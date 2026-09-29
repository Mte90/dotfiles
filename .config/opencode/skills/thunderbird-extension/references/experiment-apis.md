# Experiment APIs Reference

> This reference file is loaded on demand from ../SKILL.md for detailed Experiment API documentation.

Experiments provide access to Thunderbird internals not exposed via WebExtension APIs.

## When to Use Experiments

- Need access to internal Thunderbird services
- API functionality not yet available in MailExtension API
- Complex integrations with core features

**⚠️ Warning:** Experiments grant full, unrestricted access. Users see:
> "Have full, unrestricted access to Thunderbird, and your computer"

## Experiment Structure

```json
{
  "experiment_apis": {
    "myapi": {
      "schema": "api/myapi/schema.json",
      "parent": {
        "scopes": ["addon_parent"],
        "paths": [["myapi"]],
        "script": "api/myapi/implementation.js",
        "events": ["startup"]
      }
    }
  }
}
```

## Schema Definition (schema.json)

```json
[
  {
    "namespace": "myapi",
    "functions": [
      {
        "name": "doSomething",
        "type": "function",
        "async": true,
        "parameters": [
          {
            "name": "param",
            "type": "string"
          }
        ]
      }
    ],
    "events": [
      {
        "name": "onSomething",
        "type": "function"
      }
    ]
  }
]
```

## Implementation (implementation.js)

```javascript
class MyAPI extends ExtensionAPI {
  getAPI(context) {
    return {
      myapi: {
        async doSomething(param) {
          // Access Thunderbird internals via Services
          const { Services } = ChromeUtils.import(
            "resource://gre/modules/Services.jsm"
          );
          
          // Do something with internal APIs
          return Services.someService.process(param);
        },

        onSomething: new ExtensionCommon.EventManager({
          context,
          name: "myapi.onSomething",
          register: (fire) => {
            const callback = (data) => fire.async(data);
            
            // Register with internal service
            someInternalService.addListener(callback);
            
            return () => {
              someInternalService.removeListener(callback);
            };
          }
        }).api()
      }
    };
  }

  onStartup() {
    console.log("Extension starting up");
  }

  onShutdown(reason) {
    console.log("Extension shutting down:", reason);
    // Cleanup required
    Services.obs.notifyObservers(null, "startupcache-invalidate", null);
  }
}
```

## Using Experiment API

```javascript
// In background.js
const result = await messenger.myapi.doSomething("param");

// Listen for experiment events
messenger.myapi.onSomething.addListener((data) => {
  console.log("Event received:", data);
});
```

## Available Community Experiments

| Experiment | Description | Repository |
|------------|-------------|------------|
| Calendar | Calendar API | [webext-experiments/calendar](https://github.com/thunderbird/webext-experiments/tree/main/calendar) |
| FileSystem | File system access | [webext-support/FileSystem](https://github.com/thunderbird/webext-support/tree/master/experiments/FileSystem) |
| LegacyPrefs | Preferences access | [webext-support/LegacyPrefs](https://github.com/thunderbird/webext-support/tree/master/experiments/LegacyPrefs) |
| NotificationBox | Notification bars | [webext-experiments/NotificationBox](https://github.com/thunderbird/webext-experiments/tree/main/NotificationBox) |
| WindowListener | Window events | [webext-support/WindowListener](https://github.com/thunderbird/webext-support/tree/master/experiments/WindowListener) |