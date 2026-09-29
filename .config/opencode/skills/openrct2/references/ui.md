# UI Development Reference

This reference file is loaded on demand from ../SKILL.md when UI development details are needed.

## Check UI Availability

```javascript
// Always check before using UI APIs (for headless servers)
if (typeof ui !== 'undefined') {
    // UI is available
    ui.registerMenuItem('My Window', openWindow);
}
```

## Menu Integration

```javascript
function main() {
    if (typeof ui === 'undefined') return;
    
    // Add menu item
    ui.registerMenuItem('My Plugin', function() {
        openMainWindow();
    });
    
    // Add to specific menu tab
    ui.registerMenuItem('Ride Stats', function() {
        openRideStatsWindow();
    }, 'ride');  // 'map', 'park', 'ride', 'guest', etc.
}
```

## Window Creation

```javascript
function openMainWindow() {
    var window = ui.openWindow({
        classification: 'myplugin.main',
        title: 'My Plugin Window',
        width: 300,
        height: 200,
        widgets: [
            // Label
            {
                type: 'label',
                x: 10,
                y: 10,
                width: 280,
                height: 20,
                text: 'Hello, OpenRCT2!'
            },
            // Button
            {
                type: 'button',
                x: 10,
                y: 40,
                width: 120,
                height: 30,
                text: 'Click Me',
                onClick: function() {
                    console.log('Button clicked!');
                }
            },
            // Checkbox
            {
                type: 'checkbox',
                x: 10,
                y: 80,
                width: 200,
                height: 20,
                text: 'Enable feature',
                isChecked: false,
                onChange: function(checked) {
                    console.log('Checkbox: ' + checked);
                }
            },
            // Dropdown
            {
                type: 'dropdown',
                x: 10,
                y: 110,
                width: 200,
                height: 20,
                items: ['Option 1', 'Option 2', 'Option 3'],
                selectedIndex: 0,
                onChange: function(index) {
                    console.log('Selected: ' + index);
                }
            },
            // Slider
            {
                type: 'slider',
                x: 10,
                y: 140,
                width: 200,
                height: 20,
                minValue: 0,
                maxValue: 100,
                value: 50,
                onChange: function(value) {
                    console.log('Slider: ' + value);
                }
            },
            // Spinner
            {
                type: 'spinner',
                x: 10,
                y: 170,
                width: 100,
                height: 20,
                text: '10',
                onDecrement: function() {
                    // Handle decrement
                },
                onIncrement: function() {
                    // Handle increment
                }
            }
        ]
    });
    
    return window;
}
```

## ListView Widget

```javascript
{
    type: 'listview',
    x: 10,
    y: 10,
    width: 280,
    height: 150,
    scrollbars: 'vertical',
    isStriped: true,
    showColumnHeaders: true,
    columns: [
        { header: 'Name', width: 150 },
        { header: 'Value', width: 80 },
        { header: 'Status', width: 50 }
    ],
    items: [
        ['Ride 1', '$5000', 'OK'],
        ['Ride 2', '$3000', 'OK'],
        ['Ride 3', '$2000', 'Low']
    ],
    onHighlight: function(item, column) {
        console.log('Highlighted: ' + item + ', ' + column);
    },
    onClick: function(item, column) {
        console.log('Clicked: ' + item + ', ' + column);
    }
}
```

## GroupBox Widget

```javascript
{
    type: 'groupbox',
    x: 10,
    y: 10,
    width: 280,
    height: 100,
    text: 'Settings',
    widgets: [
        {
            type: 'checkbox',
            x: 10,
            y: 20,
            width: 260,
            height: 20,
            text: 'Enable notifications'
        },
        {
            type: 'checkbox',
            x: 10,
            y: 45,
            width: 260,
            height: 20,
            text: 'Auto-save'
        }
    ]
}
```

## Tab Window

```javascript
function openTabWindow() {
    var window = ui.openWindow({
        classification: 'myplugin.tabs',
        title: 'Tabbed Window',
        width: 400,
        height: 300,
        tabs: [
            {
                image: 5221,  // Icon ID
                widgets: [
                    {
                        type: 'label',
                        x: 10, y: 10,
                        width: 380, height: 20,
                        text: 'Tab 1 Content'
                    }
                ]
            },
            {
                image: 5222,
                widgets: [
                    {
                        type: 'label',
                        x: 10, y: 10,
                        width: 380, height: 20,
                        text: 'Tab 2 Content'
                    }
                ]
            }
        ]
    });
}
```

## Window Events

```javascript
var window = ui.openWindow({ /* ... */ });

window.onClose = function() {
    console.log('Window closed');
    // Cleanup
};
```