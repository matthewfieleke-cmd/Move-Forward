#!/usr/bin/env python3
"""Generate the Move Forward Xcode project, assets, schemes, and config files."""

from __future__ import annotations

import hashlib
import os
from pathlib import Path
from textwrap import dedent
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parents[1]


def pid(*parts: str) -> str:
    return hashlib.md5("/".join(parts).encode()).hexdigest()[:24].upper()


def write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


PRIVACY = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>C617.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
"""

IOS_INFO = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>app.moveforward</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>moveforward</string>
            </array>
        </dict>
    </array>
    <key>NSSupportsLiveActivities</key>
    <true/>
    <key>NSSupportsLiveActivitiesFrequentUpdates</key>
    <false/>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
</dict>
</plist>
"""

WATCH_INFO = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>app.moveforward.watchkitapp</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>moveforward</string>
            </array>
        </dict>
    </array>
    <key>WKApplication</key>
    <true/>
    <key>WKCompanionAppBundleIdentifier</key>
    <string>app.moveforward</string>
    <key>WKRunsIndependentlyOfCompanionApp</key>
    <true/>
</dict>
</plist>
"""

WIDGET_INFO = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.widgetkit-extension</string>
    </dict>
</dict>
</plist>
"""

ACCENT = """{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0.560",
          "green" : "0.550",
          "red" : "0.180"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""

ASSET_ROOT = """{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""

IOS_APPICON = """{
  "images" : [
    {
      "filename" : "AppIcon.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""

WATCH_APPICON = """{
  "images" : [
    {
      "filename" : "AppIcon.png",
      "idiom" : "universal",
      "platform" : "watchos",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""


def write_support_files() -> None:
    write(ROOT / "Config/Shared.xcconfig", dedent("""\
        PRODUCT_NAME = MoveForward
        MARKETING_VERSION = 1.0
        CURRENT_PROJECT_VERSION = 1
        SWIFT_VERSION = 5.0
        IPHONEOS_DEPLOYMENT_TARGET = 18.0
        WATCHOS_DEPLOYMENT_TARGET = 11.0
        CODE_SIGN_STYLE = Automatic
        DEVELOPMENT_TEAM =
        CURRENT_PROJECT_VERSION = 1
    """))
    write(ROOT / "Config/Signing.xcconfig.example", dedent("""\
        // Copy to Local.xcconfig (gitignored) and set your team ID.
        DEVELOPMENT_TEAM = YOUR_TEAM_ID
        CODE_SIGN_STYLE = Automatic
    """))
    write(ROOT / "MoveForward/Info.plist", IOS_INFO)
    write(ROOT / "MoveForwardWatch/Info.plist", WATCH_INFO)
    write(ROOT / "MoveForwardWidgets/Info.plist", WIDGET_INFO)
    write(ROOT / "MoveForwardWatchWidgets/Info.plist", WIDGET_INFO)
    for rel in [
        "MoveForward/PrivacyInfo.xcprivacy",
        "MoveForwardWatch/PrivacyInfo.xcprivacy",
        "MoveForwardWidgets/PrivacyInfo.xcprivacy",
        "MoveForwardWatchWidgets/PrivacyInfo.xcprivacy",
    ]:
        write(ROOT / rel, PRIVACY)

    write(ROOT / "MoveForward/Assets.xcassets/Contents.json", ASSET_ROOT)
    write(ROOT / "MoveForward/Assets.xcassets/AppIcon.appiconset/Contents.json", IOS_APPICON)
    write(ROOT / "MoveForward/Assets.xcassets/AccentColor.colorset/Contents.json", ACCENT)
    write(ROOT / "MoveForwardWatch/Assets.xcassets/Contents.json", ASSET_ROOT)
    write(ROOT / "MoveForwardWatch/Assets.xcassets/AppIcon.appiconset/Contents.json", WATCH_APPICON)
    write(ROOT / "MoveForwardWatch/Assets.xcassets/AccentColor.colorset/Contents.json", ACCENT)
    write(ROOT / "MoveForwardWidgets/Assets.xcassets/Contents.json", ASSET_ROOT)
    # Both widget targets set ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME, so the
    # colour has to exist in their own catalogues too.
    write(ROOT / "MoveForwardWidgets/Assets.xcassets/AccentColor.colorset/Contents.json", ACCENT)
    write(ROOT / "MoveForwardWatchWidgets/Assets.xcassets/Contents.json", ASSET_ROOT)
    write(ROOT / "MoveForwardWatchWidgets/Assets.xcassets/AccentColor.colorset/Contents.json", ACCENT)


def scheme_xml(name: str, target_id: str, test_id: str | None = None) -> str:
    test_block = ""
    if test_id:
        test_block = f"""
      <Testables>
         <TestableReference
            skipped = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{test_id}"
               BuildableName = "MoveForwardTests.xctest"
               BlueprintName = "MoveForwardTests"
               ReferencedContainer = "container:MoveForward.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>"""
    else:
        test_block = "      <Testables>\n      </Testables>"
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1600"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{target_id}"
               BuildableName = "{escape(name)}.app"
               BlueprintName = "{escape(name)}"
               ReferencedContainer = "container:MoveForward.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
{test_block}
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target_id}"
            BuildableName = "{escape(name)}.app"
            BlueprintName = "{escape(name)}"
            ReferencedContainer = "container:MoveForward.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{target_id}"
            BuildableName = "{escape(name)}.app"
            BlueprintName = "{escape(name)}"
            ReferencedContainer = "container:MoveForward.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""


def swift_names(folder: str) -> list[str]:
    return sorted(path.name for path in (ROOT / folder).glob("*.swift"))


def named(files: list[str], expected: str) -> str:
    expected_lower = expected.lower()
    for name in files:
        if name.lower() == expected_lower:
            return name
    raise FileNotFoundError(f"Missing {expected} in {files}")


def pbxproj() -> str:
    shared_domain = swift_names("SharedDomain")
    shared_app = swift_names("SharedApp")
    ios_ui = swift_names("MoveForward")
    watch_ui = swift_names("MoveForwardWatch")
    ios_widget_ui = swift_names("MoveForwardWidgets")
    watch_widget_ui = swift_names("MoveForwardWatchWidgets")
    tests = swift_names("MoveForwardTests")
    visit_models = named(shared_domain, "VisitModels.swift")
    visit_activity = named(shared_domain, "VisitActivityAttributes.swift")
    theme = named(shared_app, "Theme.swift")
    live_activity = named(ios_widget_ui, "MoveForwardLiveActivity.swift")
    chooser_complication = named(watch_widget_ui, "ChooserComplication.swift")
    tests_file = named(tests, "MoveForwardTests.swift")

    files: dict[str, tuple[str, str]] = {}

    def add_file(key: str, path: str, ftype: str) -> str:
        ident = pid("file", path)
        files[key] = (ident, path, ftype) if False else None  # type: ignore
        files[path] = (ident, ftype)
        return ident

    # rebuild cleanly
    refs: dict[str, str] = {}
    types: dict[str, str] = {}

    def add(path: str, ftype: str) -> str:
        ident = pid("ref", path)
        refs[path] = ident
        types[path] = ftype
        return ident

    for name in shared_domain:
        add(f"SharedDomain/{name}", "sourcecode.swift")
    for name in shared_app:
        add(f"SharedApp/{name}", "sourcecode.swift")
    for name in ios_ui:
        add(f"MoveForward/{name}", "sourcecode.swift")
    for name in watch_ui:
        add(f"MoveForwardWatch/{name}", "sourcecode.swift")
    for name in ios_widget_ui:
        add(f"MoveForwardWidgets/{name}", "sourcecode.swift")
    for name in watch_widget_ui:
        add(f"MoveForwardWatchWidgets/{name}", "sourcecode.swift")
    for name in tests:
        add(f"MoveForwardTests/{name}", "sourcecode.swift")

    add("MoveForward/Info.plist", "text.plist.xml")
    add("MoveForwardWatch/Info.plist", "text.plist.xml")
    add("MoveForwardWidgets/Info.plist", "text.plist.xml")
    add("MoveForwardWatchWidgets/Info.plist", "text.plist.xml")
    add("MoveForward/PrivacyInfo.xcprivacy", "text.xml")
    add("MoveForwardWatch/PrivacyInfo.xcprivacy", "text.xml")
    add("MoveForwardWidgets/PrivacyInfo.xcprivacy", "text.xml")
    add("MoveForwardWatchWidgets/PrivacyInfo.xcprivacy", "text.xml")
    add("MoveForward/Assets.xcassets", "folder.assetcatalog")
    add("MoveForwardWatch/Assets.xcassets", "folder.assetcatalog")
    add("MoveForwardWidgets/Assets.xcassets", "folder.assetcatalog")
    add("MoveForwardWatchWidgets/Assets.xcassets", "folder.assetcatalog")
    add("Config/Shared.xcconfig", "text.xcconfig")

    def build(path: str, target: str) -> str:
        return pid("build", target, path)

    ios_sources = [f"SharedDomain/{n}" for n in shared_domain] + [f"SharedApp/{n}" for n in shared_app] + [f"MoveForward/{n}" for n in ios_ui]
    watch_sources = [f"SharedDomain/{n}" for n in shared_domain] + [f"SharedApp/{n}" for n in shared_app] + [f"MoveForwardWatch/{n}" for n in watch_ui]
    ios_widget_sources = [
        f"SharedDomain/{visit_models}",
        f"SharedDomain/{visit_activity}",
        f"SharedApp/{theme}",
        f"MoveForwardWidgets/{live_activity}",
    ]
    watch_widget_sources = [
        f"SharedDomain/{visit_models}",
        f"SharedApp/{theme}",
        f"MoveForwardWatchWidgets/{chooser_complication}",
    ]
    test_sources = [f"MoveForwardTests/{tests_file}"]

    ios_resources = ["MoveForward/Assets.xcassets", "MoveForward/PrivacyInfo.xcprivacy"]
    watch_resources = ["MoveForwardWatch/Assets.xcassets", "MoveForwardWatch/PrivacyInfo.xcprivacy"]
    ios_widget_resources = ["MoveForwardWidgets/Assets.xcassets", "MoveForwardWidgets/PrivacyInfo.xcprivacy"]
    watch_widget_resources = ["MoveForwardWatchWidgets/Assets.xcassets", "MoveForwardWatchWidgets/PrivacyInfo.xcprivacy"]

    targets = {
        "ios": pid("target", "MoveForward"),
        "watch": pid("target", "MoveForwardWatch"),
        "iosw": pid("target", "MoveForwardWidgets"),
        "watchw": pid("target", "MoveForwardWatchWidgets"),
        "tests": pid("target", "MoveForwardTests"),
    }
    products = {
        "ios": pid("product", "MoveForward.app"),
        "watch": pid("product", "MoveForwardWatch.app"),
        "iosw": pid("product", "MoveForwardWidgets.appex"),
        "watchw": pid("product", "MoveForwardWatchWidgets.appex"),
        "tests": pid("product", "MoveForwardTests.xctest"),
    }
    product_refs = {
        "ios": add("MoveForward.app", "wrapper.application"),
        "watch": add("MoveForwardWatch.app", "wrapper.application"),
        "iosw": add("MoveForwardWidgets.appex", "wrapper.app-extension"),
        "watchw": add("MoveForwardWatchWidgets.appex", "wrapper.app-extension"),
        "tests": add("MoveForwardTests.xctest", "wrapper.cfbundle"),
    }

    phases = {
        "ios_src": pid("phase", "ios", "src"),
        "ios_res": pid("phase", "ios", "res"),
        "ios_fw": pid("phase", "ios", "fw"),
        "ios_embed_watch": pid("phase", "ios", "embedwatch"),
        "ios_embed_ext": pid("phase", "ios", "embedext"),
        "watch_src": pid("phase", "watch", "src"),
        "watch_res": pid("phase", "watch", "res"),
        "watch_fw": pid("phase", "watch", "fw"),
        "watch_embed_ext": pid("phase", "watch", "embedext"),
        "iosw_src": pid("phase", "iosw", "src"),
        "iosw_res": pid("phase", "iosw", "res"),
        "iosw_fw": pid("phase", "iosw", "fw"),
        "watchw_src": pid("phase", "watchw", "src"),
        "watchw_res": pid("phase", "watchw", "res"),
        "watchw_fw": pid("phase", "watchw", "fw"),
        "tests_src": pid("phase", "tests", "src"),
        "tests_fw": pid("phase", "tests", "fw"),
    }

    configs = {
        "proj_debug": pid("xc", "proj", "debug"),
        "proj_release": pid("xc", "proj", "release"),
        "ios_debug": pid("xc", "ios", "debug"),
        "ios_release": pid("xc", "ios", "release"),
        "watch_debug": pid("xc", "watch", "debug"),
        "watch_release": pid("xc", "watch", "release"),
        "iosw_debug": pid("xc", "iosw", "debug"),
        "iosw_release": pid("xc", "iosw", "release"),
        "watchw_debug": pid("xc", "watchw", "debug"),
        "watchw_release": pid("xc", "watchw", "release"),
        "tests_debug": pid("xc", "tests", "debug"),
        "tests_release": pid("xc", "tests", "release"),
    }
    lists = {
        "proj": pid("xclist", "proj"),
        "ios": pid("xclist", "ios"),
        "watch": pid("xclist", "watch"),
        "iosw": pid("xclist", "iosw"),
        "watchw": pid("xclist", "watchw"),
        "tests": pid("xclist", "tests"),
    }

    deps = {
        "ios_watch": pid("dep", "ios", "watch"),
        "ios_iosw": pid("dep", "ios", "iosw"),
        "watch_watchw": pid("dep", "watch", "watchw"),
        "tests_ios": pid("dep", "tests", "ios"),
    }
    proxies = {
        "ios_watch": pid("proxy", "ios", "watch"),
        "ios_iosw": pid("proxy", "ios", "iosw"),
        "watch_watchw": pid("proxy", "watch", "watchw"),
        "tests_ios": pid("proxy", "tests", "ios"),
    }

    embed_watch_file = pid("embedfile", "watch")
    embed_iosw_file = pid("embedfile", "iosw")
    embed_watchw_file = pid("embedfile", "watchw")

    groups = {
        "root": pid("group", "root"),
        "domain": pid("group", "SharedDomain"),
        "app": pid("group", "SharedApp"),
        "ios": pid("group", "MoveForward"),
        "watch": pid("group", "MoveForwardWatch"),
        "iosw": pid("group", "MoveForwardWidgets"),
        "watchw": pid("group", "MoveForwardWatchWidgets"),
        "tests": pid("group", "MoveForwardTests"),
        "config": pid("group", "Config"),
        "products": pid("group", "Products"),
    }
    project_id = pid("project", "MoveForward")
    xcconfig_id = refs["Config/Shared.xcconfig"]

    def children(paths: list[str]) -> str:
        return " ".join(refs[p] + " /* " + Path(p).name + " */" for p in paths)

    lines: list[str] = []
    a = lines.append
    a("// !$*UTF8*$!")
    a("{")
    a("	archiveVersion = 1;")
    a("	classes = {")
    a("	};")
    a("	objectVersion = 56;")
    a("	objects = {")

    # build files
    def src_build(path: str, target: str) -> None:
        a(f"		{build(path, target)} /* {Path(path).name} in Sources */ = {{isa = PBXBuildFile; fileRef = {refs[path]} /* {Path(path).name} */; }};")

    def res_build(path: str, target: str) -> None:
        a(f"		{build(path, target)} /* {Path(path).name} in Resources */ = {{isa = PBXBuildFile; fileRef = {refs[path]} /* {Path(path).name} */; }};")

    for path in ios_sources:
        src_build(path, "ios")
    for path in watch_sources:
        src_build(path, "watch")
    for path in ios_widget_sources:
        src_build(path, "iosw")
    for path in watch_widget_sources:
        src_build(path, "watchw")
    for path in test_sources:
        src_build(path, "tests")
    for path in ios_resources:
        res_build(path, "ios")
    for path in watch_resources:
        res_build(path, "watch")
    for path in ios_widget_resources:
        res_build(path, "iosw")
    for path in watch_widget_resources:
        res_build(path, "watchw")

    a(f"		{embed_watch_file} /* MoveForwardWatch.app in Embed Watch Content */ = {{isa = PBXBuildFile; fileRef = {product_refs['watch']} /* MoveForwardWatch.app */; settings = {{ATTRIBUTES = (CodeSignOnCopy, RemoveHeadersOnCopy, ); }}; }};")
    a(f"		{embed_iosw_file} /* MoveForwardWidgets.appex in Embed Foundation Extensions */ = {{isa = PBXBuildFile; fileRef = {product_refs['iosw']} /* MoveForwardWidgets.appex */; settings = {{ATTRIBUTES = (CodeSignOnCopy, RemoveHeadersOnCopy, ); }}; }};")
    a(f"		{embed_watchw_file} /* MoveForwardWatchWidgets.appex in Embed Foundation Extensions */ = {{isa = PBXBuildFile; fileRef = {product_refs['watchw']} /* MoveForwardWatchWidgets.appex */; settings = {{ATTRIBUTES = (CodeSignOnCopy, RemoveHeadersOnCopy, ); }}; }};")

    # container proxies
    a(f"		{proxies['ios_watch']} /* PBXContainerItemProxy */ = {{")
    a("			isa = PBXContainerItemProxy;")
    a(f"			containerPortal = {project_id} /* Project object */;")
    a("			proxyType = 1;")
    a(f"			remoteGlobalIDString = {targets['watch']};")
    a("			remoteInfo = MoveForwardWatch;")
    a("		};")
    a(f"		{proxies['ios_iosw']} /* PBXContainerItemProxy */ = {{")
    a("			isa = PBXContainerItemProxy;")
    a(f"			containerPortal = {project_id} /* Project object */;")
    a("			proxyType = 1;")
    a(f"			remoteGlobalIDString = {targets['iosw']};")
    a("			remoteInfo = MoveForwardWidgets;")
    a("		};")
    a(f"		{proxies['watch_watchw']} /* PBXContainerItemProxy */ = {{")
    a("			isa = PBXContainerItemProxy;")
    a(f"			containerPortal = {project_id} /* Project object */;")
    a("			proxyType = 1;")
    a(f"			remoteGlobalIDString = {targets['watchw']};")
    a("			remoteInfo = MoveForwardWatchWidgets;")
    a("		};")
    a(f"		{proxies['tests_ios']} /* PBXContainerItemProxy */ = {{")
    a("			isa = PBXContainerItemProxy;")
    a(f"			containerPortal = {project_id} /* Project object */;")
    a("			proxyType = 1;")
    a(f"			remoteGlobalIDString = {targets['ios']};")
    a("			remoteInfo = MoveForward;")
    a("		};")

    # copy files
    a(f"		{phases['ios_embed_watch']} /* Embed Watch Content */ = {{")
    a("			isa = PBXCopyFilesBuildPhase;")
    a("			buildActionMask = 2147483647;")
    a("			dstPath = \"$(CONTENTS_FOLDER_PATH)/Watch\";")
    a("			dstSubfolderSpec = 16;")
    a(f"			files = ( {embed_watch_file} /* MoveForwardWatch.app in Embed Watch Content */, );")
    a("			name = \"Embed Watch Content\";")
    a("			runOnlyForDeploymentPostprocessing = 0;")
    a("		};")
    a(f"		{phases['ios_embed_ext']} /* Embed Foundation Extensions */ = {{")
    a("			isa = PBXCopyFilesBuildPhase;")
    a("			buildActionMask = 2147483647;")
    a("			dstPath = \"\";")
    a("			dstSubfolderSpec = 13;")
    a(f"			files = ( {embed_iosw_file} /* MoveForwardWidgets.appex in Embed Foundation Extensions */, );")
    a("			name = \"Embed Foundation Extensions\";")
    a("			runOnlyForDeploymentPostprocessing = 0;")
    a("		};")
    a(f"		{phases['watch_embed_ext']} /* Embed Foundation Extensions */ = {{")
    a("			isa = PBXCopyFilesBuildPhase;")
    a("			buildActionMask = 2147483647;")
    a("			dstPath = \"\";")
    a("			dstSubfolderSpec = 13;")
    a(f"			files = ( {embed_watchw_file} /* MoveForwardWatchWidgets.appex in Embed Foundation Extensions */, );")
    a("			name = \"Embed Foundation Extensions\";")
    a("			runOnlyForDeploymentPostprocessing = 0;")
    a("		};")

    # file refs
    for path, ident in refs.items():
        name = Path(path).name
        ftype = types[path]
        if path.endswith(".app") or path.endswith(".appex") or path.endswith(".xctest"):
            a(f"		{ident} /* {name} */ = {{isa = PBXFileReference; explicitFileType = {ftype}; includeInIndex = 0; path = {name}; sourceTree = BUILT_PRODUCTS_DIR; }};")
        elif path.endswith(".xcassets"):
            a(f"		{ident} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; path = {name}; sourceTree = \"<group>\"; }};")
        else:
            a(f"		{ident} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; path = {name}; sourceTree = \"<group>\"; }};")

    # frameworks empty phases
    for key in ["ios_fw", "watch_fw", "iosw_fw", "watchw_fw", "tests_fw"]:
        a(f"		{phases[key]} /* Frameworks */ = {{")
        a("			isa = PBXFrameworksBuildPhase;")
        a("			buildActionMask = 2147483647;")
        a("			files = (")
        a("			);")
        a("			runOnlyForDeploymentPostprocessing = 0;")
        a("		};")

    def group(ident: str, name: str, paths: list[str], extra: str = "") -> None:
        a(f"		{ident} /* {name} */ = {{")
        a("			isa = PBXGroup;")
        a("			children = (")
        for p in paths:
            a(f"				{refs[p]} /* {Path(p).name} */,")
        if extra:
            a(extra)
        a("			);")
        a(f"			path = {name};")
        a("			sourceTree = \"<group>\";")
        a("		};")

    group(groups["domain"], "SharedDomain", [f"SharedDomain/{n}" for n in shared_domain])
    group(groups["app"], "SharedApp", [f"SharedApp/{n}" for n in shared_app])
    group(groups["ios"], "MoveForward", [f"MoveForward/{n}" for n in ios_ui] + ["MoveForward/Info.plist", "MoveForward/PrivacyInfo.xcprivacy", "MoveForward/Assets.xcassets"])
    group(groups["watch"], "MoveForwardWatch", [f"MoveForwardWatch/{n}" for n in watch_ui] + ["MoveForwardWatch/Info.plist", "MoveForwardWatch/PrivacyInfo.xcprivacy", "MoveForwardWatch/Assets.xcassets"])
    group(groups["iosw"], "MoveForwardWidgets", [f"MoveForwardWidgets/{n}" for n in ios_widget_ui] + ["MoveForwardWidgets/Info.plist", "MoveForwardWidgets/PrivacyInfo.xcprivacy", "MoveForwardWidgets/Assets.xcassets"])
    group(groups["watchw"], "MoveForwardWatchWidgets", [f"MoveForwardWatchWidgets/{n}" for n in watch_widget_ui] + ["MoveForwardWatchWidgets/Info.plist", "MoveForwardWatchWidgets/PrivacyInfo.xcprivacy", "MoveForwardWatchWidgets/Assets.xcassets"])
    group(groups["tests"], "MoveForwardTests", [f"MoveForwardTests/{n}" for n in tests])
    group(groups["config"], "Config", ["Config/Shared.xcconfig"])

    a(f"		{groups['products']} /* Products */ = {{")
    a("			isa = PBXGroup;")
    a("			children = (")
    a(f"				{product_refs['ios']} /* MoveForward.app */,")
    a(f"				{product_refs['watch']} /* MoveForwardWatch.app */,")
    a(f"				{product_refs['iosw']} /* MoveForwardWidgets.appex */,")
    a(f"				{product_refs['watchw']} /* MoveForwardWatchWidgets.appex */,")
    a(f"				{product_refs['tests']} /* MoveForwardTests.xctest */,")
    a("			);")
    a("			name = Products;")
    a("			sourceTree = \"<group>\";")
    a("		};")
    a(f"		{groups['root']} = {{")
    a("			isa = PBXGroup;")
    a("			children = (")
    a(f"				{groups['domain']} /* SharedDomain */,")
    a(f"				{groups['app']} /* SharedApp */,")
    a(f"				{groups['ios']} /* MoveForward */,")
    a(f"				{groups['watch']} /* MoveForwardWatch */,")
    a(f"				{groups['iosw']} /* MoveForwardWidgets */,")
    a(f"				{groups['watchw']} /* MoveForwardWatchWidgets */,")
    a(f"				{groups['tests']} /* MoveForwardTests */,")
    a(f"				{groups['config']} /* Config */,")
    a(f"				{groups['products']} /* Products */,")
    a("			);")
    a("			sourceTree = \"<group>\";")
    a("		};")

    def native(ident: str, name: str, product: str, product_ref: str, ptype: str, src: str, res: str | None, fw: str, extras: list[str], deps: list[str], cfg: str) -> None:
        a(f"		{ident} /* {name} */ = {{")
        a("			isa = PBXNativeTarget;")
        a(f"			buildConfigurationList = {cfg} /* Build configuration list for PBXNativeTarget \"{name}\" */;")
        a("			buildPhases = (")
        a(f"				{src} /* Sources */,")
        a(f"				{fw} /* Frameworks */,")
        if res:
            a(f"				{res} /* Resources */,")
        for extra in extras:
            a(f"				{extra},")
        a("			);")
        a("			buildRules = (")
        a("			);")
        a("			dependencies = (")
        for dep in deps:
            a(f"				{dep} /* PBXTargetDependency */,")
        a("			);")
        a(f"			name = {name};")
        a(f"			productName = {name};")
        a(f"			productReference = {product_ref} /* {product} */;")
        a(f"			productType = \"{ptype}\";")
        a("		};")

    native(targets["ios"], "MoveForward", "MoveForward.app", product_refs["ios"], "com.apple.product-type.application", phases["ios_src"], phases["ios_res"], phases["ios_fw"], [f"{phases['ios_embed_watch']} /* Embed Watch Content */", f"{phases['ios_embed_ext']} /* Embed Foundation Extensions */"], [deps["ios_watch"], deps["ios_iosw"]], lists["ios"])
    native(targets["watch"], "MoveForwardWatch", "MoveForwardWatch.app", product_refs["watch"], "com.apple.product-type.application", phases["watch_src"], phases["watch_res"], phases["watch_fw"], [f"{phases['watch_embed_ext']} /* Embed Foundation Extensions */"], [deps["watch_watchw"]], lists["watch"])
    native(targets["iosw"], "MoveForwardWidgets", "MoveForwardWidgets.appex", product_refs["iosw"], "com.apple.product-type.app-extension", phases["iosw_src"], phases["iosw_res"], phases["iosw_fw"], [], [], lists["iosw"])
    native(targets["watchw"], "MoveForwardWatchWidgets", "MoveForwardWatchWidgets.appex", product_refs["watchw"], "com.apple.product-type.app-extension", phases["watchw_src"], phases["watchw_res"], phases["watchw_fw"], [], [], lists["watchw"])
    native(targets["tests"], "MoveForwardTests", "MoveForwardTests.xctest", product_refs["tests"], "com.apple.product-type.bundle.unit-test", phases["tests_src"], None, phases["tests_fw"], [], [deps["tests_ios"]], lists["tests"])

    a(f"		{project_id} /* Project object */ = {{")
    a("			isa = PBXProject;")
    a("			attributes = {")
    a("				BuildIndependentTargetsInParallel = 1;")
    a("				LastSwiftUpdateCheck = 1600;")
    a("				LastUpgradeCheck = 1600;")
    a("				TargetAttributes = {")
    for key in ["ios", "watch", "iosw", "watchw", "tests"]:
        a(f"					{targets[key]} = {{")
        a("						CreatedOnToolsVersion = 16.0;")
        a("					};")
    a("				};")
    a("			};")
    a(f"			buildConfigurationList = {lists['proj']} /* Build configuration list for PBXProject \"MoveForward\" */;")
    a("			compatibilityVersion = \"Xcode 15.0\";")
    a("			developmentRegion = en;")
    a("			hasScannedForEncodings = 0;")
    a("			knownRegions = (")
    a("				en,")
    a("				Base,")
    a("			);")
    a(f"			mainGroup = {groups['root']};")
    a(f"			productRefGroup = {groups['products']} /* Products */;")
    a("			projectDirPath = \"\";")
    a("			projectRoot = \"\";")
    a("			targets = (")
    a(f"				{targets['ios']} /* MoveForward */,")
    a(f"				{targets['watch']} /* MoveForwardWatch */,")
    a(f"				{targets['iosw']} /* MoveForwardWidgets */,")
    a(f"				{targets['watchw']} /* MoveForwardWatchWidgets */,")
    a(f"				{targets['tests']} /* MoveForwardTests */,")
    a("			);")
    a("		};")

    def resources(ident: str, paths: list[str], target: str) -> None:
        a(f"		{ident} /* Resources */ = {{")
        a("			isa = PBXResourcesBuildPhase;")
        a("			buildActionMask = 2147483647;")
        a("			files = (")
        for path in paths:
            a(f"				{build(path, target)} /* {Path(path).name} in Resources */,")
        a("			);")
        a("			runOnlyForDeploymentPostprocessing = 0;")
        a("		};")

    def sources(ident: str, paths: list[str], target: str) -> None:
        a(f"		{ident} /* Sources */ = {{")
        a("			isa = PBXSourcesBuildPhase;")
        a("			buildActionMask = 2147483647;")
        a("			files = (")
        for path in paths:
            a(f"				{build(path, target)} /* {Path(path).name} in Sources */,")
        a("			);")
        a("			runOnlyForDeploymentPostprocessing = 0;")
        a("		};")

    sources(phases["ios_src"], ios_sources, "ios")
    sources(phases["watch_src"], watch_sources, "watch")
    sources(phases["iosw_src"], ios_widget_sources, "iosw")
    sources(phases["watchw_src"], watch_widget_sources, "watchw")
    sources(phases["tests_src"], test_sources, "tests")
    resources(phases["ios_res"], ios_resources, "ios")
    resources(phases["watch_res"], watch_resources, "watch")
    resources(phases["iosw_res"], ios_widget_resources, "iosw")
    resources(phases["watchw_res"], watch_widget_resources, "watchw")

    def dependency(ident: str, target: str, proxy: str, name: str) -> None:
        a(f"		{ident} /* PBXTargetDependency */ = {{")
        a("			isa = PBXTargetDependency;")
        a(f"			target = {target} /* {name} */;")
        a(f"			targetProxy = {proxy} /* PBXContainerItemProxy */;")
        a("		};")

    dependency(deps["ios_watch"], targets["watch"], proxies["ios_watch"], "MoveForwardWatch")
    dependency(deps["ios_iosw"], targets["iosw"], proxies["ios_iosw"], "MoveForwardWidgets")
    dependency(deps["watch_watchw"], targets["watchw"], proxies["watch_watchw"], "MoveForwardWatchWidgets")
    dependency(deps["tests_ios"], targets["ios"], proxies["tests_ios"], "MoveForward")

    common_debug = """
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				IPHONEOS_DEPLOYMENT_TARGET = 18.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				ONLY_ACTIVE_ARCH = YES;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
				SWIFT_STRICT_CONCURRENCY = targeted;
				SWIFT_VERSION = 5.0;
				WATCHOS_DEPLOYMENT_TARGET = 11.0;
"""
    common_release = """
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				IPHONEOS_DEPLOYMENT_TARGET = 18.0;
				MTL_ENABLE_DEBUG_INFO = NO;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_STRICT_CONCURRENCY = targeted;
				SWIFT_VERSION = 5.0;
				WATCHOS_DEPLOYMENT_TARGET = 11.0;
"""

    a(f"		{configs['proj_debug']} /* Debug */ = {{")
    a("			isa = XCBuildConfiguration;")
    a(f"			baseConfigurationReference = {xcconfig_id} /* Shared.xcconfig */;")
    a("			buildSettings = {")
    a(common_debug)
    a("			};")
    a("			name = Debug;")
    a("		};")
    a(f"		{configs['proj_release']} /* Release */ = {{")
    a("			isa = XCBuildConfiguration;")
    a(f"			baseConfigurationReference = {xcconfig_id} /* Shared.xcconfig */;")
    a("			buildSettings = {")
    a(common_release)
    a("			};")
    a("			name = Release;")
    a("		};")

    def target_cfg(ident: str, name: str, settings: str) -> None:
        a(f"		{ident} /* {name} */ = {{")
        a("			isa = XCBuildConfiguration;")
        a("			buildSettings = {")
        a(settings)
        a("			};")
        a(f"			name = {name};")
        a("		};")

    ios_settings_debug = """
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				DEVELOPMENT_TEAM = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = MoveForward/Info.plist;
				INFOPLIST_KEY_CFBundleDisplayName = "Move Forward";
				INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.medical";
				INFOPLIST_KEY_NSSupportsLiveActivities = YES;
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				PRODUCT_BUNDLE_IDENTIFIER = app.moveforward;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = iphoneos;
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO;
				SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 1;
"""
    watch_settings_debug = """
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				DEVELOPMENT_TEAM = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = MoveForwardWatch/Info.plist;
				INFOPLIST_KEY_CFBundleDisplayName = "Move Forward";
				INFOPLIST_KEY_WKApplication = YES;
				INFOPLIST_KEY_WKCompanionAppBundleIdentifier = app.moveforward;
				INFOPLIST_KEY_WKRunsIndependentlyOfCompanionApp = YES;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				PRODUCT_BUNDLE_IDENTIFIER = app.moveforward.watchkitapp;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = watchos;
				SKIP_INSTALL = YES;
				SUPPORTED_PLATFORMS = "watchos watchsimulator";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 4;
				WATCHOS_DEPLOYMENT_TARGET = 11.0;
"""
    iosw_settings = """
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				DEVELOPMENT_TEAM = "";
				APPLICATION_EXTENSION_API_ONLY = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = MoveForwardWidgets/Info.plist;
				INFOPLIST_KEY_CFBundleDisplayName = "Move Forward";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
					"@executable_path/../../Frameworks",
				);
				PRODUCT_BUNDLE_IDENTIFIER = app.moveforward.widgets;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = iphoneos;
				SKIP_INSTALL = YES;
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 1;
"""
    watchw_settings = """
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				DEVELOPMENT_TEAM = "";
				APPLICATION_EXTENSION_API_ONLY = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = MoveForwardWatchWidgets/Info.plist;
				INFOPLIST_KEY_CFBundleDisplayName = "Move Forward";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
					"@executable_path/../../Frameworks",
				);
				PRODUCT_BUNDLE_IDENTIFIER = app.moveforward.watchkitapp.widgets;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = watchos;
				SKIP_INSTALL = YES;
				SUPPORTED_PLATFORMS = "watchos watchsimulator";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 4;
				WATCHOS_DEPLOYMENT_TARGET = 11.0;
"""
    tests_settings = """
				BUNDLE_LOADER = "$(TEST_HOST)";
				CODE_SIGN_STYLE = Automatic;
				DEVELOPMENT_TEAM = "";
				GENERATE_INFOPLIST_FILE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 18.0;
				PRODUCT_BUNDLE_IDENTIFIER = app.moveforward.tests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = iphoneos;
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 1;
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/MoveForward.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/MoveForward";
"""

    target_cfg(configs["ios_debug"], "Debug", ios_settings_debug)
    target_cfg(configs["ios_release"], "Release", ios_settings_debug.replace("dwarf;", "dwarf;").replace("ENABLE_PREVIEWS = YES;", "ENABLE_PREVIEWS = YES;"))
    target_cfg(configs["watch_debug"], "Debug", watch_settings_debug)
    target_cfg(configs["watch_release"], "Release", watch_settings_debug)
    target_cfg(configs["iosw_debug"], "Debug", iosw_settings)
    target_cfg(configs["iosw_release"], "Release", iosw_settings)
    target_cfg(configs["watchw_debug"], "Debug", watchw_settings)
    target_cfg(configs["watchw_release"], "Release", watchw_settings)
    target_cfg(configs["tests_debug"], "Debug", tests_settings)
    target_cfg(configs["tests_release"], "Release", tests_settings)

    def cfg_list(ident: str, title: str, debug: str, release: str) -> None:
        a(f"		{ident} /* Build configuration list for {title} */ = {{")
        a("			isa = XCConfigurationList;")
        a("			buildConfigurations = (")
        a(f"				{debug} /* Debug */,")
        a(f"				{release} /* Release */,")
        a("			);")
        a("			defaultConfigurationIsVisible = 0;")
        a("			defaultConfigurationName = Release;")
        a("		};")

    cfg_list(lists["proj"], 'PBXProject "MoveForward"', configs["proj_debug"], configs["proj_release"])
    cfg_list(lists["ios"], 'PBXNativeTarget "MoveForward"', configs["ios_debug"], configs["ios_release"])
    cfg_list(lists["watch"], 'PBXNativeTarget "MoveForwardWatch"', configs["watch_debug"], configs["watch_release"])
    cfg_list(lists["iosw"], 'PBXNativeTarget "MoveForwardWidgets"', configs["iosw_debug"], configs["iosw_release"])
    cfg_list(lists["watchw"], 'PBXNativeTarget "MoveForwardWatchWidgets"', configs["watchw_debug"], configs["watchw_release"])
    cfg_list(lists["tests"], 'PBXNativeTarget "MoveForwardTests"', configs["tests_debug"], configs["tests_release"])

    a("	};")
    a(f"	rootObject = {project_id} /* Project object */;")
    a("}")

    write(ROOT / "MoveForward.xcodeproj/xcshareddata/xcschemes/MoveForward.xcscheme", scheme_xml("MoveForward", targets["ios"], targets["tests"]))
    write(ROOT / "MoveForward.xcodeproj/xcshareddata/xcschemes/MoveForwardWatch.xcscheme", scheme_xml("MoveForwardWatch", targets["watch"]))
    write(ROOT / "MoveForward.xcodeproj/project.xcworkspace/contents.xcworkspacedata", """<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:">
   </FileRef>
</Workspace>
""")
    return "\n".join(lines) + "\n", targets


def main() -> None:
    write_support_files()
    content, _ = pbxproj()
    write(ROOT / "MoveForward.xcodeproj/project.pbxproj", content)
    print("Wrote Xcode project, assets, Info.plist files, and schemes.")


if __name__ == "__main__":
    main()
