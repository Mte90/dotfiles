# Adding Features to an APK

## 10.1 Creating New Smali Classes from Scratch

When adding features, you'll often need to create new `.smali` files. Smali class files follow a strict naming convention that must match their directory path:

```smali
# File: decompiled/smali/com/example/patch/FeatureManager.smali

.class public Lcom/example/patch/FeatureManager;
.super Ljava/lang/Object;

# Instance fields (class member variables)
.field private mContext:Landroid/content/Context;
.field private mEnabled:Z
.field private mConfig:Ljava/lang/String;

# Static fields
.field private static final TAG:Ljava/lang/String; = "FeatureManager"

# Direct method (constructor)
.method public constructor <init>(Landroid/content/Context;)V
    .registers 3
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    iput-object p1, p0, Lcom/example/patch/FeatureManager;->mContext:Landroid/content/Context;
    const/4 v0, 0x1
    iput-boolean v0, p0, Lcom/example/patch/FeatureManager;->mEnabled:Z
    const-string v0, "default"
    iput-object v0, p0, Lcom/example/patch/FeatureManager;->mConfig:Ljava/lang/String;
    return-void
.end method

# Instance method
.method public doSomething(Ljava/lang/String;)Z
    .registers 4

    # Log entry
    const-string v0, "FeatureManager"
    const-string v1, "doSomething called"
    invoke-static {v0, v1}, Landroid/util/Log;->d(Ljava/lang/String;Ljava/lang/String;)I

    # Use context
    iget-object v0, p0, Lcom/example/patch/FeatureManager;->mContext:Landroid/content/Context;
    if-eqz v0, :cond_error

    # Get SharedPreferences
    const-string v1, "patch_prefs"
    const/4 v2, 0x0
    invoke-virtual {v0, v1, v2}, Landroid/content/Context;->getSharedPreferences(Ljava/lang/String;I)Landroid/content/SharedPreferences;
    move-result-object v0

    # Store a value
    invoke-interface {v0}, Landroid/content/SharedPreferences;->edit()Landroid/content/SharedPreferences$Editor;
    move-result-object v0
    const-string v1, "last_action"
    invoke-interface {v0, v1, p1}, Landroid/content/SharedPreferences$Editor;->putString(Ljava/lang/String;Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;
    invoke-interface {v0}, Landroid/content/SharedPreferences$Editor;->apply()V

    # Return success
    const/4 v0, 0x1
    return v0

    :cond_error
    const/4 v0, 0x0
    return v0
.end method

# Method to check if feature is enabled
.method public isEnabled()Z
    .registers 2
    iget-boolean v0, p0, Lcom/example/patch/FeatureManager;->mEnabled:Z
    return v0
.end method

# Method to enable/disable feature
.method public setEnabled(Z)V
    .registers 2
    iput-boolean p1, p0, Lcom/example/patch/FeatureManager;->mEnabled:Z
    return-void
.end method
```

**Key rules for creating smali files**:
- The file path must match the class name: `Lcom/example/patch/FeatureManager;` → `smali/com/example/patch/FeatureManager.smali`
- Use `.registers N` to declare the total number of registers (params + locals)
- `p0` = `this`, `p1` = first parameter, etc.
- Use `v0, v1, ...` for local variables
- Always declare `.field` entries for class member variables
- Constructor must be named `<init>` and return `V` (void)

## 10.2 Adding a New Activity to the App

To add a new screen/Activity to an existing app, you need to create both the smali class and register it in `AndroidManifest.xml`:

**Step 1: Create the Activity smali file**

```smali
# File: decompiled/smali/com/example/patch/SettingsActivity.smali

.class public Lcom/example/patch/SettingsActivity;
.super Landroidx/appcompat/app/AppCompatActivity;

# Required: static field for layout ID (set after building resources)
# .field private static final LAYOUT_ID:I = 0x7f0b001c

.method public constructor <init>()V
    .registers 1
    invoke-direct {p0}, Landroidx/appcompat/app/AppCompatActivity;-><init>()V
    return-void
.end method

.method protected onCreate(Landroid/os/Bundle;)V
    .registers 3

    invoke-super {p0, p1}, Landroidx/appcompat/app/AppCompatActivity;->onCreate(Landroid/os/Bundle;)V

    # Set content view (use an existing layout ID from the app, or create a new one)
    const v0, 0x7f0b001c   # Replace with actual layout resource ID
    invoke-virtual {p0, v0}, Landroid/app/Activity;->setContentView(I)V

    # Set title
    const-string v1, "Patch Settings"
    invoke-virtual {p0, v1}, Landroid/app/Activity;->setTitle(Ljava/lang/CharSequence;)V

    # Find a TextView and set text
    const v0, 0x7f0a0001    # R.id.some_textview - replace with real ID
    invoke-virtual {p0, v0}, Landroid/app/Activity;->findViewById(I)Landroid/view/View;
    move-result-object v0
    check-cast v0, Landroid/widget/TextView;
    const-string v1, "Feature enabled!"
    invoke-virtual {v0, v1}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    return-void
.end method
```

**Step 2: Create a layout XML for the Activity**

```xml
<!-- File: decompiled/res/layout/patch_settings.xml -->
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="16dp">

    <TextView
        android:id="@+id/patch_title"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Patch Settings"
        android:textSize="24sp"
        android:textStyle="bold" />

    <Switch
        android:id="@+id/feature_switch"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="16dp"
        android:text="Enable Feature" />

    <Button
        android:id="@+id/save_button"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginTop="16dp"
        android:text="Save" />
</LinearLayout>
```

**Step 3: Register in AndroidManifest.xml**

```xml
<!-- Add inside <application> tag -->
<activity
    android:name="com.example.patch.SettingsActivity"
    android:exported="false"
    android:label="Patch Settings" />
```

**Step 4: Add a way to launch the new Activity from the existing app**

Find a suitable hook point in the existing app (e.g., a settings menu, an "About" screen) and add an intent:

```smali
# In the existing Activity's smali (e.g., SettingsScreen.smali)
# After the existing menu items, add:

# Create intent to launch our new Activity
new-instance v0, Landroid/content/Intent;
invoke-direct {v0, p0, Lcom/example/patch/SettingsActivity;};
invoke-virtual {p0, v0}, Landroid/app/Activity;->startActivity(Landroid/content/Intent;)V
```

**Finding resource IDs for your new layout**: After recompiling, apktool assigns resource IDs. To know them in advance, look at the existing `public.xml` or `res/values/public.xml` — or more practically, compile once without ID references, check the `R.java` equivalent in the build output, then update your smali with the correct IDs.

## 10.3 Adding External Libraries (.jar / .aar)

When your new feature needs a library that the original app doesn't include:

**Adding a .jar file (Java library)**:

```bash
# 1. Convert .jar to smali using baksmali (so it can be merged into the DEX)
baksmali d library.jar -o lib_smali/

# 2. Copy the smali output into the app's smali directory
cp -r lib_smali/* decompiled/smali/

# 3. If the library has its own resources (rare for .jar), merge them
# Most .jar files don't have Android resources
```

**Adding an .aar file (Android library with resources)**:

```bash
# 1. Extract the .aar (it's a ZIP file)
mkdir aar_extracted && cd aar_extracted
unzip ../library.aar

# Contents typically include:
#   classes.jar       — compiled Java code
#   AndroidManifest.xml
#   res/              — resources
#   R.txt             — resource definitions
#   proguard.txt

# 2. Convert classes.jar to smali and merge
baksmali d classes.jar -o jar_smali/
cp -r jar_smali/* ../decompiled/smali/

# 3. Merge resources into the app's res/ directory
cp -r res/* ../decompiled/res/

# 4. Register any activities/services from the library's manifest
# Merge relevant entries into decompiled/AndroidManifest.xml

# 5. Handle resource ID conflicts
# If the library defines resource IDs that clash with the app's,
# you may need to rename them in the smali that references them
```

**Adding a pre-compiled .dex file**:

```bash
# Simply copy into the smali directory and baksmali it
baksmali d library.dex -o lib_smali/
cp -r lib_smali/* decompiled/smali/
```

## 10.4 Injecting Code into the App Lifecycle

The most reliable way to run your new code is to hook into the Application class's lifecycle. Every Android app has an Application class that's created before any Activity.

**Strategy A: Modify the existing Application class**

```bash
# 1. Find the Application class
# Check AndroidManifest.xml for: android:name=".MyApplication"
# If not specified, the default is android.app.Application

# 2. Find the smali file
# If android:name="com.example.app.MyApp":
#   ls decompiled/smali/com/example/app/MyApp.smali

# 3. Add your initialization to its attachBaseContext or onCreate
```

```smali
# In the Application class's attachBaseContext method, add:
.method protected attachBaseContext(Landroid/content/Context;)V
    .registers 3

    # YOUR CODE: Initialize FeatureManager
    new-instance v0, Lcom/example/patch/FeatureManager;
    invoke-direct {v0, p1}, Lcom/example/patch/FeatureManager;-><init>(Landroid/content/Context;)V
    sput-object v0, Lcom/example/patch/FeatureManager;->INSTANCE:Lcom/example/patch/FeatureManager;

    # YOUR CODE: Log that the patch is active
    const-string v0, "PatchManager"
    const-string v1, "Patch initialized successfully"
    invoke-static {v0, v1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    # Call the original super method
    invoke-super {p0, p1}, Landroid/app/Application;->attachBaseContext(Landroid/content/Context;)V
    return-void
.end method
```

**Strategy B: Replace the Application class in the manifest (if none exists or it's simple)**

```xml
<!-- AndroidManifest.xml -->
<application
    android:name="com.example.patch.PatchedApplication"
    ... >
```

```smali
# File: decompiled/smali/com/example/patch/PatchedApplication.smali

.class public Lcom/example/patch/PatchedApplication;
.super Landroid/app/Application;

# Singleton instance
.field private static sInstance:Lcom/example/patch/PatchedApplication;

.method public constructor <init>()V
    .registers 1
    invoke-direct {p0}, Landroid/app/Application;-><init>()V
    return-void
.end method

.method public static getInstance()Lcom/example/patch/PatchedApplication;
    .registers 1
    sget-object v0, Lcom/example/patch/PatchedApplication;->sInstance:Lcom/example/patch/PatchedApplication;
    return-object v0
.end method

.method public onCreate()V
    .registers 3

    # Store singleton
    sput-object p0, Lcom/example/patch/PatchedApplication;->sInstance:Lcom/example/patch/PatchedApplication;

    # Call super
    invoke-super {p0}, Landroid/app/Application;->onCreate()V

    # Initialize your features here
    const-string v0, "PatchedApp"
    const-string v1, "Application onCreate - patch active"
    invoke-static {v0, v1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    # Initialize FeatureManager
    new-instance v0, Lcom/example/patch/FeatureManager;
    invoke-direct {v0, p0}, Lcom/example/patch/FeatureManager;-><init>(Landroid/content/Context;)V
    sput-object v0, Lcom/example/patch/FeatureManager;->INSTANCE:Lcom/example/patch/FeatureManager;

    return-void
.end method
```

## 10.5 Handling Multi-DEX When Adding Code

Android has a 65,536 method limit per DEX file (`classes.dex`). If you're adding substantial code (especially entire libraries), you may hit this limit during recompilation:

```
# Error message:
trouble writing output: too many method references: 67000; max is 65536

# Error message:
com.android.dex.DexIndexOverflowException: method ID not in [0, 0xffff]: 65536
```

**Solutions**:

**Solution 1: Let apktool handle multi-dex automatically**

Apktool 2.11.0 supports multi-dex output. When the method count exceeds the limit, it creates `classes2.dex`, `classes3.dex`, etc. This usually works transparently.

**Solution 2: Put your new code in a separate DEX file explicitly**

```bash
# Create your new code as a separate .dex
smali new_code_smali/ -o classes2.dex

# Place it alongside the existing classes.dex
cp classes2.dex decompiled/smali_classes2.dex  # NOT standard — see below

# Actually, apktool expects smali directories, not DEX files.
# The correct approach:
mkdir -p decompiled/smali_classes2/com/example/patch/
cp new_feature_smali/*.smali decompiled/smali_classes2/com/example/patch/
```

Apktool will compile each `smali*` directory into a separate DEX file. The Android runtime handles multi-dex automatically on Android 5.0+ (API 21). For apps with `minSdkVersion < 21`, a MultiDex support library is needed — but virtually all modern apps target API 21+.

**Solution 3: Remove unused code first**

If you're close to the limit, you can strip unused classes before adding your code:

```bash
# Search for and remove unused third-party classes
# Common candidates for removal:
# - Analytics SDKs you don't need (com/google/android/gms/analytics/*)
# - Unused language resources
# - Ad SDK classes (if removing ads)

rm -rf decompiled/smali/com/google/android/gms/internal/analytics/
```

## 10.6 Practical Example: Adding a "Debug Panel" to Any App

Here's a complete, practical example of adding a floating debug panel that shows log messages:

**Step 1: Create the DebugPanel smali**

```smali
# File: decompiled/smali/com/example/patch/DebugPanel.smali

.class public Lcom/example/patch/DebugPanel;
.super Landroid/widget/TextView;

.implements Landroid/view/View$OnTouchListener;

.field private mDragging:Z
.field private mLastX:F
.field private mLastY:F

.method public constructor <init>(Landroid/content/Context;)V
    .registers 2
    invoke-direct {p0, p1}, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V
    invoke-direct {p0}, Lcom/example/patch/DebugPanel;->setup()V
done

.method private setup()V
    .registers 3

    const-string v0, "PATCH"
    invoke-virtual {p0, v0}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    const/16 v0, 0x11   # Gravity center
    invoke-virtual {p0, v0}, Landroid/widget/TextView;->setGravity(I)V

    const/high16 v0, -0x10000   # 0xFFFF0000 = RED
    invoke-virtual {p0, v0}, Landroid/widget/TextView;->setTextColor(I)V

    const v0, 0xCC000000   # Semi-transparent black background
    invoke-virtual {p0, v0}, Landroid/widget/TextView;->setBackgroundColor(I)V

    const/4 v0, 0x2         # Padding in pixels
    invoke-virtual {p0, v0, v0, v0, v0}, Landroid/widget/TextView;->setPadding(IIII)V

    invoke-virtual {p0, p0}, Landroid/widget/TextView;->setOnTouchListener(Landroid/view/View$OnTouchListener;)V
    return-void
.done

.method public onTouch(Landroid/view/View;Landroid/view/MotionEvent;)Z
    .registers 8

    invoke-virtual {p2}, Landroid/view/MotionEvent;->getAction()I
    move-result v0

    packed-switch v0, :pswitch_data_0

    const/4 v0, 0x1
    return v0

    :pswitch_0    # ACTION_DOWN
    const/4 v0, 0x1
    iput-boolean v0, p0, Lcom/example/patch/DebugPanel;->mDragging:Z

    invoke-virtual {p2}, Landroid/view/MotionEvent;->getRawX()F
    move-result v0
    iput v0, p0, Lcom/example/patch/DebugPanel;->mLastX:F

    invoke-virtual {p2}, Landroid/view/MotionEvent;->getRawY()F
    move-result v0
    iput v0, p0, Lcom/example/patch/DebugPanel;->mLastY:F

    const/4 v0, 0x1
    return v0

    :pswitch_1    # ACTION_MOVE
    iget-boolean v0, p0, Lcom/example/patch/DebugPanel;->mDragging:Z
    if-eqz v0, :cond_done

    invoke-virtual {p2}, Landroid/view/MotionEvent;->getRawX()F
    move-result v1
    invoke-virtual {p2}, Landroid/view/MotionEvent;->getRawY()F
    move-result v2

    iget v3, p0, Lcom/example/patch/DebugPanel;->mLastX:F
    sub-float v3, v1, v3

    iget v4, p0, Lcom/example/patch/DebugPanel;->mLastY:F
    sub-float v4, v2, v4

    invoke-virtual {p0}, Landroid/widget/TextView;->getLeft()I
    move-result v5
    int-to-float v5, v5
    add-float/2addr v5, v3

    invoke-virtual {p0}, Landroid/widget/TextView;->getTop()I
    move-result v3
    int-to-float v3, v3
    add-float/2addr v3, v4

    float-to-int v3, v3
    invoke-virtual {p0, v5, v3}, Landroid/widget/TextView;->layout(II)V

    iput v1, p0, Lcom/example/patch/DebugPanel;->mLastX:F
    iput v2, p0, Lcom/example/patch/DebugPanel;->mLastY:F

    const/4 v0, 0x1
    return v0

    :cond_done
    const/4 v0, 0x0
    return v0

    :pswitch_2    # ACTION_UP
    const/4 v0, 0x0
    iput-boolean v0, p0, Lcom/example/patch/DebugPanel;->mDragging:Z

    const/4 v0, 0x1
    return v0

    :pswitch_data_0
    .packed-switch 0x0
        :pswitch_0    # ACTION_DOWN
        :pswitch_1    # ACTION_MOVE
        :pswitch_2    # ACTION_UP
    .end packed-switch
.done
```

**Step 2: Attach the panel to the main Activity**

```smali
# In the main Activity's onCreate, after setContentView:

# Create the debug panel
new-instance v0, Lcom/example/patch/DebugPanel;
invoke-direct {v0, p0}, Lcom/example/patch/DebugPanel;-><init>(Landroid/content/Context;)V

# Set layout params: wrap_content, positioned at top-right
new-instance v1, Landroid/widget/FrameLayout$LayoutParams;
const/4 v2, -0x2    # WRAP_CONTENT
const/4 v3, -0x2    # WRAP_CONTENT
invoke-direct {v1, v2, v3}, Landroid/widget/FrameLayout$LayoutParams;-><init>(II)V

const/16 v2, 0x31  # Gravity.RIGHT | Gravity.TOP

# Add to the root view
invoke-virtual {p0}, Landroid/app/Activity;->getWindow()Landroid/view/Window;
move-result-object v2
invoke-virtual {v2}, Landroid/view/Window;->getDecorView()Landroid/view/View;
move-result-object v2
check-cast v2, Landroid/view/ViewGroup;
invoke-virtual {v2, v0, v1}, Landroid/view/ViewGroup;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V
```

**Step 3: Add necessary permissions and imports** — The above uses `android.util.Log`, which is part of the standard Android SDK, so no additional permissions are needed.
