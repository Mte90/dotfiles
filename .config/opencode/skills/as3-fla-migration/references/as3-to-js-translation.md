# AS3 to JavaScript/TypeScript Translation Reference

## Core Language Mapping

### Types and Variables

| ActionScript 3 | JavaScript / TypeScript |
|---------------|------------------------|
| `int`, `uint` | `number` |
| `Number` | `number` |
| `Boolean` | `boolean` |
| `String` | `string` |
| `Array` | `Array<T>` / `T[]` |
| `Vector.<T>` | `Array<T>` (or `Int32Array` etc.) |
| `Object` | `object` / `Record<string, any>` |
| `void` | `void` |
| `*` (untyped) | `any` |
| `var x:int = 5` | `let x: number = 5` |
| `const X:int = 5` | `const X: number = 5` |
| `trace("msg")` | `console.log("msg")` |
| `typeof(x)` | `typeof x` |
| `x is Type` | `x instanceof Type` |
| `x as Type` | `x as Type` (TS) |
| `x as String` | `String(x)` |

### Classes and OOP

| AS3 | JavaScript / TypeScript |
|-----|------------------------|
| `package com.game { }` | `namespace com.game { }` (rare) or just directories |
| `class Player extends Sprite` | `class Player extends Container` |
| `public/private/protected` | `public/private/protected` (TS) or `#` private (JS) |
| `static` | `static` |
| `override` | N/A (just redefine method) |
| `final` | `readonly` (TS) |
| `interface IGame` | `interface IGame` (TS) |
| `[Bindable]` metadata | Framework-specific (e.g., signals) |
| `get/set` accessors | `get name() { }` (TS) |
| `function fn(...args):*` | `function fn(...args: any[]): any` |

**AS3 class example:**
```actionscript
package com.game.entities {
    import flash.display.Sprite;

    public class Player extends Sprite {
        private var _speed:Number = 5;
        private var _health:int = 100;

        public function Player() {
            super();
            this.graphics.beginFill(0xFF0000);
            this.graphics.drawCircle(0, 0, 20);
            this.graphics.endFill();
        }

        public function get speed():Number { return _speed; }
        public function set speed(val:Number):void { _speed = val; }

        public function move(dx:Number, dy:Number):void {
            this.x += dx * _speed;
            this.y += dy * _speed;
        }

        public function takeDamage(amount:int):void {
            _health -= amount;
            if (_health <= 0) {
                destroy();
            }
        }

        private function destroy():void {
            this.parent.removeChild(this);
        }
    }
}
```

**TypeScript equivalent:**
```typescript
class Player extends createjs.Container {
    private _speed: number = 5;
    private _health: number = 100;

    constructor() {
        super();

        const g = new createjs.Graphics();
        g.beginFill("#FF0000").drawCircle(0, 0, 20).endFill();
        this.graphics = g;
    }

    get speed(): number { return this._speed; }
    set speed(val: number) { this._speed = val; }

    move(dx: number, dy: number): void {
        this.x += dx * this._speed;
        this.y += dy * this._speed;
    }

    takeDamage(amount: number): void {
        this._health -= amount;
        if (this._health <= 0) {
            this.destroy();
        }
    }

    private destroy(): void {
        if (this.parent) {
            this.parent.removeChild(this);
        }
    }
}
```

### Events

| AS3 | JavaScript / CreateJS |
|-----|----------------------|
| `addEventListener(Event.ENTER_FRAME, fn)` | `createjs.Ticker.addEventListener("tick", fn)` |
| `addEventListener(MouseEvent.CLICK, fn)` | `this.on("click", fn)` |
| `addEventListener("customEvent", fn)` | `this.on("customEvent", fn)` |
| `dispatchEvent(new Event("done"))` | `this.emit("done")` or `this.dispatchEvent("done")` |
| `removeEventListener(type, fn)` | `this.off(type, fn)` |
| `Event(type)` | `{ type, target }` plain object |

### Display List

| AS3 | CreateJS |
|-----|----------|
| `stage.addChild(child)` | `stage.addChild(child)` |
| `stage.removeChild(child)` | `stage.removeChild(child)` |
| `container.numChildren` | `container.numChildren` |
| `container.getChildAt(i)` | `container.getChildAt(i)` |
| `container.getChildByName("name")` | `container.getChildByName("name")` |
| `child.parent` | `child.parent` |
| `child.x`, `child.y` | `child.x`, `child.y` |
| `child.width`, `child.height` | `child.getBounds().width` (may need cache) |
| `child.alpha = 0.5` | `child.alpha = 0.5` |
| `child.visible = false` | `child.visible = false` |
| `child.rotation = 45` | `child.rotation = 45` |
| `child.scaleX = 2` | `child.scaleX = 2` |
| `child.mask = maskShape` | `child.mask = maskShape` |
| `child.filters = [blur]` | `child.filters = [blur]` |
| `child.blendMode` | `child.compositeOperation` |
| `child.buttonMode = true` | `child.cursor = "pointer"` |
| `child.mouseChildren = false` | `child.mouseChildren = false` |
| `child.hitArea` | `child.hitArea` |
| `new Shape()` | `new createjs.Shape()` |
| `new Sprite()` | `new createjs.Sprite()` |
| `new Bitmap(bmpData)` | `new createjs.Bitmap(imageSrc)` |
| `new TextField()` | `new createjs.Text("text", "font", "color")` |
| `new MovieClip()` | `new createjs.MovieClip()` |
| `new SimpleButton()` | Custom button class with hit states |

### Graphics API

| AS3 `Graphics` | Canvas / CreateJS `Graphics` |
|---------------|------------------------------|
| `g.beginFill(0xFF0000)` | `g.beginFill("#FF0000")` |
| `g.beginGradientFill(...)` | `g.beginLinearGradientFill(...)` |
| `g.endFill()` | `g.endFill()` |
| `g.moveTo(x, y)` | `g.moveTo(x, y)` |
| `g.lineTo(x, y)` | `g.lineTo(x, y)` |
| `g.drawCircle(x, y, r)` | `g.drawCircle(x, y, r)` |
| `g.drawEllipse(x, y, w, h)` | `g.drawEllipse(x, y, w, h)` |
| `g.drawRect(x, y, w, h)` | `g.drawRect(x, y, w, h)` |
| `g.drawRoundRect(...)` | `g.drawRoundRect(...)` |
| `g.clear()` | `g.clear()` |
| `g.lineStyle(2, 0x000000)` | `g.setStrokeStyle(2).beginStroke("#000000")` |
| `g.lineGradientStyle(...)` | `g.beginStroke().command` (complex) |

### Timer and Animation

| AS3 | JavaScript |
|-----|-----------|
| `new Timer(1000, 5)` | `setInterval(fn, 1000)` with counter |
| `timer.start()` | (immediate with setInterval) |
| `timer.stop()` | `clearInterval(id)` |
| `getTimer()` | `performance.now()` |
| `ENTER_FRAME` | `requestAnimationFrame` or `createjs.Ticker` |
| `flash.utils.setInterval` | `setInterval` |
| `flash.utils.setTimeout` | `setTimeout` |
| `flash.utils.clearInterval` | `clearInterval` |
| `flash.utils.clearTimeout` | `clearTimeout` |

### Tweening

| AS3 (Typical Tween Library) | CreateJS TweenJS |
|---------------------------|------------------|
| `TweenLite.to(obj, 1, {x:100})` | `createjs.Tween.get(obj).to({x:100}, 1000)` |
| `TweenLite.from(obj, 1, {alpha:0})` | `createjs.Tween.get(obj).from({alpha:0}, 1000)` |
| `TweenLite.to(obj, 1, {x:100, y:50, ease:Elastic.easeOut})` | `createjs.Tween.get(obj).to({x:100, y:50}, 1000, createjs.Ease.elasticOut)` |
| `TweenLite.delayedCall(2, fn)` | `createjs.Tween.get().wait(2000).call(fn)` |
| `TweenMax.to(obj, 1, {x:100, repeat:3})` | `createjs.Tween.get(obj).to({x:100}, 1000).to({x:0}, 1000)` (loop manually) |

### Sound

| AS3 | Web Audio / CreateJS SoundJS |
|-----|------------------------------|
| `new Sound(new URLRequest("sfx.mp3"))` | `createjs.Sound.registerSound("sfx.mp3")` |
| `sound.play()` | `createjs.Sound.play("sfx")` |
| `channel = sound.play(0, loops)` | `createjs.Sound.play("sfx", {loop: loops})` |
| `channel.stop()` | `instance.stop()` |
| `channel.soundTransform.volume = 0.5` | `instance.volume = 0.5` |
| `SoundMixer.stopAll()` | `createjs.Sound.stop()` |
| `SoundMixer.volume = 0.5` | `createjs.Sound.volume = 0.5` |

### Loading External Data

| AS3 | JavaScript |
|-----|-----------|
| `new URLLoader()` | `fetch()` / `XMLHttpRequest` |
| `new Loader()` | `new Image()` / `createjs.LoadQueue` |
| `URLLoaderDataFormat.TEXT` | Response as text |
| `URLLoaderDataFormat.BINARY` | `ArrayBuffer` |
| `loader.contentLoaderInfo.addEventListener(Event.COMPLETE, fn)` | `img.onload = fn` / `queue.on("complete", fn)` |
| `loader.load(new URLRequest("data.xml"))` | `fetch("data.xml").then(r => r.text())` |
| `XML(event.target.data)` | `new DOMParser().parseFromString(text, "text/xml")` |
| `JSON.decode(str)` | `JSON.parse(str)` |

### Math Utilities

| AS3 | JavaScript |
|-----|-----------|
| `Math.random()` | `Math.random()` |
| `Math.floor(x)` | `Math.floor(x)` |
| `Math.ceil(x)` | `Math.ceil(x)` |
| `Math.round(x)` | `Math.round(x)` |
| `Math.abs(x)` | `Math.abs(x)` |
| `Math.min(a, b)` | `Math.min(a, b)` |
| `Math.max(a, b)` | `Math.max(a, b)` |
| `Math.sin(x)` | `Math.sin(x)` |
| `Math.cos(x)` | `Math.cos(x)` |
| `Math.atan2(y, x)` | `Math.atan2(y, x)` |
| `Math.PI` | `Math.PI` |
| `Point.distance(p1, p2)` | `Math.hypot(p2.x-p1.x, p2.y-p1.y)` |
| `Point.angle(p1, p2)` | `Math.atan2(p2.y-p1.y, p2.x-p1.x)` |

### Data Structures

| AS3 | JavaScript |
|-----|-----------|
| `Array` (dynamic) | `Array` / `Map` |
| `Dictionary` | `Map<K,V>` or `Record<K,V>` |
| `Vector.<T>` | `Array<T>` or typed arrays |
| `ByteArray` | `Uint8Array` / `DataView` / `ArrayBuffer` |
| `flash.utils.getTimer()` | `performance.now()` |
| `flash.net.SharedObject` | `localStorage` / `IndexedDB` |

### Strings

| AS3 | JavaScript |
|-----|-----------|
| `str.indexOf("x")` | `str.indexOf("x")` |
| `str.lastIndexOf("x")` | `str.lastIndexOf("x")` |
| `str.substring(start, end)` | `str.substring(start, end)` |
| `str.split(",")` | `str.split(",")` |
| `str.replace("a", "b")` | `str.replace("a", "b")` |
| `str.toUpperCase()` | `str.toUpperCase()` |
| `str.toLowerCase()` | `str.toLowerCase()` |
| `str.length` | `str.length` |
| `int(str)` | `parseInt(str)` |
| `Number(str)` | `parseFloat(str)` |
| `String(num)` | `String(num)` or `num.toString()` |

## Common Patterns Translation

### Singleton Pattern

**AS3:**
```actionscript
public class GameManager {
    private static var _instance:GameManager;
    public static function get instance():GameManager {
        if (!_instance) _instance = new GameManager();
        return _instance;
    }
}
```

**TypeScript:**
```typescript
class GameManager {
    private static _instance: GameManager;
    public static get instance(): GameManager {
        if (!this._instance) this._instance = new GameManager();
        return this._instance;
    }
}
```

### State Machine Pattern

**AS3:**
```actionscript
public class GameStateMachine {
    private var _currentState:IState;
    
    public function changeState(newState:IState):void {
        if (_currentState) _currentState.exit();
        _currentState = newState;
        _currentState.enter();
    }
    
    public function update():void {
        _currentState.update();
    }
}
```

**TypeScript:**
```typescript
class GameStateMachine {
    private _currentState: IState;

    changeState(newState: IState): void {
        if (this._currentState) this._currentState.exit();
        this._currentState = newState;
        this._currentState.enter();
    }

    update(): void {
        this._currentState.update();
    }
}
```

### Object Pool Pattern

**AS3:**
```actionscript
public class Pool {
    private static var _pools:Object = {};
    
    public static function get(className:String):* {
        // ... pool logic
    }
}
```

**TypeScript:**
```typescript
class ObjectPool<T> {
    private pool: T[] = [];
    private factory: () => T;

    constructor(factory: () => T) {
        this.factory = factory;
    }

    get(): T {
        return this.pool.pop() ?? this.factory();
    }

    release(obj: T): void {
        this.pool.push(obj);
    }
}
```
