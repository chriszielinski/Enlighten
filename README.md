Enlighten 💡
===========
 
<p align="center">
	<a href="http://cocoadocs.org/docsets/Enlighten" style="text-decoration:none">
		<img alt="Platform" src ="https://img.shields.io/cocoapods/p/Enlighten.svg?style=flat"/>
	</a>
	<a href="http://cocoadocs.org/docsets/Enlighten/" style="text-decoration:none">
		<img alt="Pod Version" src ="https://img.shields.io/cocoapods/v/Enlighten.svg?style=flat"/>
	</a>
	<a href="https://github.com/Carthage/Carthage" style="text-decoration:none">
		<img alt="Carthage compatible" src ="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat"/>
	</a>
	<a href="https://developer.apple.com/swift" style="text-decoration:none">
		<img alt="Swift Version" src ="https://img.shields.io/badge/language-swift%204.2-brightgreen.svg"/>
	</a>
	<a href="https://github.com/chriszielinski/Enlighten/blob/master/LICENSE" style="text-decoration:none">
		<img alt="GitHub license" src ="https://img.shields.io/badge/license-MIT-blue.svg"/>
	</a>
	<br>
	<img src ="https://raw.githubusercontent.com/chriszielinski/Enlighten/master/readme-assets/gifs/enlighten.gif"/>
	<br>
	<br>
	<b>An integrated spotlight-based onboarding and help library for macOS, written in Swift.</b>
	<br>
</p>

---

### Looking for...
- A Floating Action Button for macOS? Check out [Fab.](https://github.com/chriszielinski/Fab) 🛍️.
- An Expanding Bubble Text Field for macOS? Check out [BubbleTextField](https://github.com/chriszielinski/BubbleTextField) 💬.


Features
========

- [x] Integrated onboarding using a _spotlight_ and rendered CommonMark Markdown strings/files.
- [x] A help button that presents a popover with app-specific help documentation rendered from CommonMark Markdown strings/files.
- [x] Use a CommonMark Markdown string/file as a tooltip.
- [x] Dark mode ready.

  <img src="https://raw.githubusercontent.com/chriszielinski/Enlighten/master/readme-assets/pngs/light-dark-mode.png" alt="Light Dark Mode Supported" width="400">


Installation
============
`Enlighten` is available for installation using CocoaPods or Carthage.


### Using [Carthage](https://github.com/Carthage/Carthage)

```ruby
github "chriszielinski/Enlighten"
```

### Using [CocoaPods](http://cocoapods.org/)

```ruby
pod "Enlighten"
```

Requirements
===========

- macOS 10.12+ (10.13+ for the custom URL scheme handler) 


Terminology
===========

* **Stage** — A single "step" in the onboarding spotlight presentation. It consists of a Markdown string rendered inside the popover.
* **Iris** — A class that encapsulates the behavior of the spotlight for a particular view. It encapsulates at least one stage; optionally, more. All the stages of the iris share the iris' configuration, unless they override the appropriate property (e.g. the `popoverMaxWidth` property). The focus/unfocus animation groups/methods are invoked upon presenting the iris' first stage and leaving the iris' last stage, respectively.
* **Followspot** — A _wider_, more encompassing spotlight used during the animated transitioning from one view (or iris) to the next.

  <img src="https://raw.githubusercontent.com/chriszielinski/Enlighten/master/readme-assets/pngs/followspot.png" alt="Followspot" width="300">
 	
* **Profile Spot** — A _tighter_, "smaller", focused spotlight used to draw attention to a particular view (or iris).
  
  <img src="https://raw.githubusercontent.com/chriszielinski/Enlighten/master/readme-assets/pngs/profile-spot.png" alt="Profile Spot" width="300">


Components
==========

The demo project provides a comprehensive, documentented example of how to integrate and configure the various components of the `Enlighten` library.

Enlighten Spotlight Controller
--------------------

There are two spotlight controllers available to use:

 * `EnlightenSpotlightController` — The basic controller that presents the irises in the order they are added.
 * `EnlightenKeyedSpotlightController` — The keyed controller that allows the presentation order of the irises to be specified by the case order of an `EnlightenSpotlightControllerKeys`-conforming enumeration.

---

### Key-less Spotlight Controller Quick Start
 
The code below will create a four-stage `EnlightenSpotlightController` comprised of two irises. It illustrates the various ways of creating/adding irises and stages.

> 📣 **Note:** The irises will be presented in the order they are added to the spotlight controller. In this example, the `firstIris` (and its stages) will be presented first, with the `secondIris` following.
 
```swift
// Create the controller.
let spotlightController = EnlightenSpotlightController()

// Create an iris with a single stage.
let firstIris = EnlightenIris(view: aView, markdownString: "This is a `NSView`.")
// Add another stage to the iris.
firstIris.addAdditionalStage(using: "This is the iris' second stage.")
// Create a third stage.
let thirdStage = EnlightenIrisStage(markdownString: "This is the **third** stage!")
// Add the third stage to the iris.
firstIris.addAdditional(stage: thirdStage)
// Add the iris to the spotlight controller.
spotlightController.addSpotlight(iris: firstIris)

// This is a convenience method for creating and adding an iris to the controller.
let secondIris = spotlightController.addSpotlight(view: anotherView, markdownString: "This is another `NSView`.")
```
 
---
 
### Keyed Spotlight Controller Quick Start

The methods used above are also available for the `EnlightenKeyedSpotlightController` with only a few requiring an additional argument—the key. But first, we must define a key enumeration whose case declaration order will correspond directly to the owning iris' presentation order.

> 🎡 **Try:** Switch the order of the `SpotlightKey` cases to change the presentation order.

```swift
// The keys that define the presentation order of the keyed spotlight controller's irises. The keys can also be used for identification purposes.
enum SpotlightKey: String, EnlightenSpotlightControllerKeys {
    // The controller will begin with the iris that corresponds to this key.
    case firstView
    // And finish with the iris that corresponds to this key.
    case secondView
}

/// Create a keyed spotlight controller using the `SpotlightKey` enum to specify the presentation order.
let keyedSpotlightController = EnlightenKeyedSpotlightController(keys: SpotlightKey.self)

// Create a keyed iris with a single stage.
let firstIris = EnlightenKeyedIris(presentationOrderKey: SpotlightKey.firstView,
                                   view: aView,
                                   markdownString: "This is a `NSView`.")
// Add another stage to the keyed iris.
firstIris.addAdditionalStage(using: "This is the iris' second stage.")
// Create a third stage.
let thirdStage = EnlightenIrisStage(markdownString: "This is the **third** stage!")
// Add the third stage to the keyed iris.
firstIris.addAdditional(stage: thirdStage)
// Add the keyed iris to the keyed spotlight controller.
keyedSpotlightController.addSpotlight(iris: firstIris)

// This is a convenience method for creating and adding a keyed iris to the keyed controller.
let secondIris = keyedSpotlightController.addSpotlight(presentationOrderKey: .secondView,
                                                       view: anotherView,
                                                       markdownString: "This is another `NSView`.")
```

---

### Presentation

Presenting and dismissing a spotlight controller is simple.

> 📣 **Note:** The controller dismisses itself upon navigating through all the stages. 

```swift
aSpotlightController.present()
aSpotlightController.dismiss()
```

---

### Followspot Shape

Configure the _followspot_ shape (the larger, moving spotlight).

```swift
spotlightController.followspotShape = .circle
```

The _followspot_ shape can be set to the following values:

* `.circle` (default)

  <img src="https://raw.githubusercontent.com/chriszielinski/Enlighten/master/readme-assets/gifs/profile-spot-circle.gif" alt=".circle Followspot Shape" height="200">

* `.none`

  <img src="https://raw.githubusercontent.com/chriszielinski/Enlighten/master/readme-assets/gifs/profile-spot-none.gif" alt=".none Followspot Shape" height="200">

* `.ellipse`

  <img src="https://raw.githubusercontent.com/chriszielinski/Enlighten/master/readme-assets/gifs/profile-spot-ellipse.gif" alt=".ellipse Followspot Shape" height="200">

### Uses Profile Spot

When using a circle or ellipse _followspot_, the _profile spot_ is optional. You can specify your preference by setting the controller's `usesProfileSpot` property. It has a default value of `true`. 

A `.circle` _followspot_ with no _profile spot_ looks like so:
<div style="text-align:center;">
	<img src="https://raw.githubusercontent.com/chriszielinski/Enlighten/master/readme-assets/gifs/no-profile-spot-circle.gif" alt="Circle Followspot with no Profile Spot" width="500">
</div>

### Delegate

You can set the spotlight controller's delegate to an `EnlightenSpotlightControllerDelegate`-conforming class to receive events.

```swift
spotlightController.delegate = self
```

The set of optional methods that Enlighten spotlight controller delegates can implement:

```swift
/// Invoked before the controller shows a stage.
func spotlightControllerWillShow(stage: Int, in iris: EnlightenIris, navigating: EnlightenSpotlightController.NavigationDirection) {}

/// Invoked when the controller has finished dismissing.
func spotlightControllerDidDismiss() {}

/// Invoked when a Markdown string fails to load, this method optionally returns a replacement.
///
/// If the delegate does not implement this method or returns nil, the spotlight stage is skipped.
///
/// - Note: This delegate method should not be necessary if appropriate testing procedures are employed to ensure
///         that all Markdown strings load successfully (i.e. `EnlightenSpotlightController.validateMarkdownStrings()`
///         testing method).
func spotlightControllerFailedToLoad(markdownString: String, for iris: EnlightenIris, with error: Error) -> String? {}
```


Enlighten Help Button
---------------------

A help button that displays a popover with app-specific help documentation rendered from a CommonMark Markdown string. 

There are two ways to create an `EnlightenHelpButton`: Interface Builder, or programmatically. The demo uses a multi-page `EnlightenHelpButton` created in the Interface Builder.

<div style="text-align:center;">
	<img src="https://raw.githubusercontent.com/chriszielinski/Enlighten/master/readme-assets/gifs/enlighten-help-button.gif" alt="Enlighten Help Button" width="500">
</div>
<br>
<br>

Programmatically, it would look something like this.

> 📣 **Note:** If you enjoy making financial transactions on a public wifi network over an HTTP connection, go ahead and use that `try!`. You're gonna have to use some really funky Markdown to throw an error.

```swift
// The Markdown string to render.
let helpButtonMarkdownString = "**Need help?** – Something that's helpful."
// Create the help button.
let enlightenHelpButton = try! EnlightenHelpButton(markdownString: helpButtonMarkdownString)
// And that's it... you still need to add it to the view hierarchy, of course.

// Optionally, you can have the popover be detachable, which allows the popover to be dragged into its own _floating_ window.
enlightenHelpButton.canDetach = true
```

### Delegate

You can set the help button's delegate to an `EnlightenPopoverDelegate`-conforming class to receive events.

```swift
enlightenHelpButton.enlightenPopoverDelegate = self
```

The set of optional methods that Enlighten popover delegates can implement:

```swift
/// Invoked when an Enlighten URL scheme was clicked in the popover.
func enlightenPopover(didClickEnlighten url: URL) {}

/// Invoked when a Markdown string fails to load, this method optionally returns a replacement.
func enlightenPopoverFailedToLoad(downError: Error) -> String? {}
```


Tooltips
--------

It may be useful to craft your spotlight controller stages' Markdown content in such a way that they can also be used as plaintext tooltips.

> 🔥 Kill two birds with one stone.

<div style="text-align:center;">
	<img src="https://raw.githubusercontent.com/chriszielinski/Enlighten/master/readme-assets/pngs/tooltip.png" alt="Enlighten Tooltip" width="500">
</div>
<br>
<br>

You can set a `NSView`'s tooltip from a Markdown string as so:

> 📣 **Note:** If you enjoy eating raw cookie dough and refueling your car with the engine on, go ahead and use that `try!`. You're gonna have to use some really funky Markdown to throw an error.

```swift
let helpButtonToolTip = """
    # Need help?

    **This is a Markdown string**, stripped of any _styling_.
    """
try? aView.enlightenTooltip(markdownString: helpButtonToolTip)
```

And from the Markdown file named 'tooltip.md' located in the main bundle:

```swift
try? aView.enlightenTooltip(markdownFilename: "tooltip", in: Bundle.main)
```


Documentation
=============

There's a basket of other configurable properties available to make your onboarding experience/help documentation perfect. You can explore the docs [here](http://chriszielinski.github.io/Enlighten/).


// ToDo:
========

- [ ] Tests.


Community
=========

- Found a bug? Open an [issue](https://github.com/chriszielinski/enlighten/issues).
- Feature idea? ~~Open an [issue](https://github.com/chriszielinski/enlighten/issues).~~ Do it yourself & PR when done 😅 (or you can open an issue 🙄).
- Want to contribute? Submit a [pull request](https://github.com/chriszielinski/enlighten/pulls).


Contributors
============

- [Chris Zielinski](https://github.com/chriszielinski) — Original author.


Frameworks & Libraries
=====================

`Enlighten` depends on the wonderful contributions of the Swift community, namely:

* **[iwasrobbed/Down](https://github.com/iwasrobbed/Down)** — Blazing fast Markdown/CommonMark rendering in Swift, built upon cmark.
* **[realm/jazzy](https://github.com/realm/jazzy)** — Soulful docs for Swift & Objective-C.
* **[realm/SwiftLint](https://github.com/realm/SwiftLint)** — A tool to enforce Swift style and conventions.


License
=======

Enlighten is available under the MIT license, see the [LICENSE](https://github.com/chriszielinski/enlighten/blob/master/LICENSE) file for more information.
