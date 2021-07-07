# OAuth Redirect Example

This sample demonstrates an approach to using OAuth2 for authenticating with an ArcGIS portal.
Unlike the pattern used in other samples where an `AuthenticationView` displays a log-in screen 
using a `WebView` within the App itself, this example sends an authorization request to an external
browser along with a redirect URL. The user can then authenticate securely in the browser 
(using their ArcGIS.com credentials) and upon successful authentication, the redirect URL 
is notified with an authorization code to allow the log-in process to continue.

In order for the call-back to the redirect URL to be handled by the app, it is necessary to 
register a custom URL protocol on the user's operating system: the process for doing this is
different on each platform. 

## Setting up an App with a custom Url protocol
The custom Url protocol defines a base URL which will be handled by the App itself rather than a browser.

### Register your App online
The first step is to register a new App by visiting [the Developers page](http://links.esri.com/qtRegisterNewApp).

Once you have logged on you can "Register New Application" to set up your app.

Make a note of the `Client Id` for the App - this is what you will use in your App to begin the log-in process.

### Add a Redirect URL
Switch to the "Authentication" tab and scroll down to "Redirect URIs" section at the bottom of the page.

Add the custom URL scheme you wish to use with the App - e.g. "exampleapp". This will be the base for the 
redirect URL that your App will be set to handle.

### Add the ClientID to your app
Open the file `OAuthRedirectExample.pro` file and set your ClientID which you obtained when you registered
your App online to be the new value for `CLIENT_ID` - e.g. DEFINES +="CLIENT_ID=\"XXXXXXXXXXX\"" where "XXXXXXXXXXX" is your ClientID.
Set the URL scheme you defined to be the new value of `URL_SCHEME`.

## Register the custom URL scheme
Registering a custom URL scheme is handled differently on each platform. On some platforms there are a number of ways this can be achieved.
This sample outlines some approaches for each of the supported platforms which can be used while developing.
When releasing a product you will need to determine the best way to carry out the registration of the URL scheme on your user's systems.

### Windows
On Windows, the custom URL protocol is setup using a registry setting which provides the path to an executable
which should be run when the URL scheme is opened. This sample uses `QSettings` to set up the registry setting at runtime,
using the path to the App's executable.

In order for the exectuable to be runnable from the registry path, all dependencies for the App must be deployed even when
running from QtCreator. An example deployment script (`windows_deployment.bat`) has been included in the sample to 
help with this process but you will need to update the various variables used such as the location of the `QT_KIT`
and the `ARCGIS_SDK_DIR`.

When the executable is called via the registry path a new instance of the App will be launched: however, in this example,
the desired behaviour is that the same instance of the App should be notified with the authorization code. To achieve this,
on windows the sample makes use of the `QtSingleApplication` from qt-solutions. Using this type, the original instance 
is notified of the authorization code as a command line argument.

### Linux
_NOTE - As there are a variety of approaches for defining a custom URL protocol on linux platforms,
this sample is not fully supported on these systems. For example, the following approach for defining a URL scheme
on Linux may work when Mozilla Firefox is the browser used for authentication.
Another approach is to set the custom protocol as a MIME-Type in a *.desktop file._

First build the project and take a note of the absolute path to the App - check the App can be run directly by entering this path from a terminal.
There are a number of ways to record the protocol for Firefox:

#### Option 1:
In a terminal, type:

    `gconftool-2 -s /desktop/gnome/url-handlers/foo/command '/path/to/app %s' --type String`
    `gconftool-2 -s /desktop/gnome/url-handlers/foo/enabled --type Boolean true`

Replace foo on both lines with the protocol you want to register and /path/to/app with the path to your App.

#### Option 2:
Alternatively, in the Firefox browser, type `about:config` into the address bar and hit Enter.
Right-click -> New -> Boolean -> Name: network.protocol-handler.expose.foo -> Value -> false (Replace foo with the protocol you're specifying)

Next time you click a link of protocol-type foo you will be asked which application to open it with - enter the path to your App.
You can try out the protocol by entering `exampleapp://hello` in a new Firefox tab.


When the App is launched from the browser a new instance will be launched: however, in this example,
the desired behaviour is that the same instance of the App should be notified with the authorization code.
To achieve this, on Linux the sample makes use of the `QtSingleApplication` from qt-solutions.
Using this type, the original instance is notified of the authorization code as a command line argument.

### Mac
In order to register a custom URL protocol on Mac whilst developing, you can define a scheme in XCode.

First, build the project in QtCreator. Next, to create an XCode project from QtCreator add the follwoing additional arguments add additional arguments to the project's qmake build settings

    `-spec macx-xcode`

Open the generated project (e.g. `OAuthRedirectExample.xcodeproj`) in XCode. 

You may need to adjust the Qt Postlink step created by QtCreator to point to the target which XCode will build (e.g. to reference the OAuthRedirectExample.app in the sub directory for Debug or Release).
E.g. Go to Build Phases/Qt PostLink and edit the script to look something like:

`
install_name_tool -change libEsriCommonQt.dylib "~/ArcGIS_SDKs/Qt100.11/sdk/macOS/x64/lib/libEsriCommonQt.dylib" Release/OAuthRedirectExample.app/Contents/MacOS/OAuthRedirectExample
`

Next go to Info/URL Types and add a new URL type with Identifier and URL Schemes set to the custom URL scheme you set up for your App.

Now when you build and run the Project from XCode, the URL scheme will be recognised and the URL will be treated as a `QFileOpenEvent`.

_NOTE: When deploying an App on Mac it should be possible to set the URL type in the Info.Plist as is done for iOS platforms._

### Android
On Android, the custom URL scheme is handled with an Activity (see `MyActivity.java`) that handles an intent to open the custom URL by calling a JNI function exposed by the application. 

The Custom URL scheme is set up in the `AndroidManifest.xml` file.
You need to update `<data android:scheme="exampleapp"/>` to use your own scheme in place of "exampleapp".

The JNI call results in a call to `QDesktopServices::openUrl` which will be handled by the App.

### iOS
On iOS, the `Info.plist` file defines the custom URL scheme.
You need to update the following code with your custome URL scheme in place of `exampleapp`:

`
<key>CFBundleURLSchemes</key>
<array>
    <string>exampleapp</string>
</array>
`

The App will then be notified of the URL as a `QFileOpenEvent`.

## QtSingleApplication dependency
On Windows and Linux, the sample depends upon the `QtSingleApplication` type from qt-solutions.
You can download the project from [GitHub](http://links.esri.com/qtSingleApplication).
The sample is designed to include the source files directly: update the `QT_SINGLEAPP_DIR`
variable in `OAuthRedirectExample.pro` to point to the location you unpack it to.

## Relevant API

- AuthenticationChallenge
- AuthenticationManager
- Portal
