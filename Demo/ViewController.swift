//
//  ViewController.swift
//  Demo
//
//  Created by Chris Zielinski on 10/25/18.
//  Copyright © 2018 Big Z Labs. All rights reserved.
//

import Cocoa
import Enlighten

class ViewController: NSViewController {
    /// Keys that define the presentation order of the keyed spotlight controller's irises. The keys can also be used for identification purposes.
    ///
    /// The order of the keys' declarations corresponds directly to their presentation order (i.e. the iris with the `.presentButton` presentation order key will be first, followed by `.customView`...).
    enum SpotlightKey: String, EnlightenSpotlightControllerKeys {
        // The controller will begin with the iris that corresponds to this key.
        case presentButton
        case customView
        case usesProfileSpotButton
        case textView
        case followspotShapeSegmentedControl
        // And finish with the iris that corresponds to this key.
        case enlightenHelpButton
    }

    /// Represents a Markdown page in the `EnlightenHelpButton` popover.
    enum HelpPage: String {
        case mainPage
        case seeMorePage
    }

    @IBOutlet var presentButton: NSButton!
    @IBOutlet var usesProfileSpotButton: NSButton!
    @IBOutlet var followspotShapeSegmentedControl: NSSegmentedControl!
    @IBOutlet var enlightenHelpButton: EnlightenHelpButton!
    @IBOutlet var textView: NSTextView!
    @IBOutlet var customView: CustomView!

    var keyedSpotlightController: EnlightenKeyedSpotlightController<SpotlightKey>!

    /// The Markdown string for the help button's main page.
    let helpButtonMainPageMarkdown = """
        **What is Lorem Ipsum?** – Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged.

        **Why do we use it?** – It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout. The point of using Lorem Ipsum is that it has a more-or-less normal distribution of letters, as opposed to using 'Content here, content here', making it look like readable English.

        **Where does it come from?** – Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin literature from 45 BC, making it over 2000 years old.

        > "I intend to live forever. So far, so good. 🔥" - Steven Wright

        [See more](enlighten://\(HelpPage.seeMorePage.rawValue))
        """

    /// The Markdown string for the help button's 'See More' page.
    let helpButtonSeeMorePageMarkdown = """
        <img src='https://media.giphy.com/media/3oKIPEh5Lk3RGSIFEI/giphy.gif' alt='More' width='384'>
        <br><br>

        I'm detachable, drag me!

        [< Back](enlighten://\(HelpPage.mainPage.rawValue))
        """

    /// The Markdown string used for the 'Uses Profile Spot' check button.
    var usesProfileSpotMarkdown: String {
        let isUsingProfileSpotMarkdown = keyedSpotlightController.usesProfileSpot
            ? ", like it is right now."
            : "."
        return "I'm the `usesProfileSpot` property. I set whether the spotlight goes into a _Profile Spot_ (the spotlight tightens on to the view)\(isUsingProfileSpotMarkdown)"
    }

    /// Creates and configures the spotlight controller.
    ///
    /// There are two spotlight controllers available to use:
    ///   * `EnlightenSpotlightController` - The basic controller that presents the irises in the order they
    ///     are added.
    ///   * `EnlightenKeyedSpotlightController` - The keyed controller that allows the presentation order of the
    ///     irises to be specified by the case order of an `EnlightenSpotlightControllerKeys`-conforming
    ///     enumeration.
    ///
    /// For didactic purposes, the demo will use the latter; although, the former would work in this case as well.
    func setupSpotlightController() {
        /// Create a keyed spotlight controller using the `SpotlightKey` enum to specify the presentation order.
        keyedSpotlightController = EnlightenKeyedSpotlightController(keys: SpotlightKey.self)
        /// Set the delegate to ourselves.
        keyedSpotlightController.delegate = self

        /// Set the default popover maximum width. The actual width of the popover will (attempt to) be constrained to the bounds of the window and will be "fitted" to the Markdown content.
        EnlightenIris.popoverMaxWidth = 480


        // MARK: 'Uses Profile Spot' Button Iris

        /// Create a keyed iris for the 'Uses Profile Spot' check button with a Markdown string.
        let usesProfileSpotButtonIris = EnlightenKeyedIris(presentationOrderKey: SpotlightKey.usesProfileSpotButton,
                                                           view: usesProfileSpotButton,
                                                           markdownString: usesProfileSpotMarkdown)

        /// Set the max width of this iris' popover. It will take precedence over the default `EnlightenIris.popoverMaxWidth` we set before.
        usesProfileSpotButtonIris.popoverMaxWidth = 250
        /// The max width of the popover can even be specified for each stage, individually.
        /// Doing so would look like this:
//        let firstStage = usesProfileSpotButtonIris.stage(index: 1)!
//        firstStage.popoverMaxWidth = 25

        /// The check button will require a custom profile spot mask because it contains text on a
        /// transparent background. In the custom drawing handler, we need to "fill in" the area we want masked, which
        /// in this case is the entire layer.
        usesProfileSpotButtonIris.profileSpotDrawingHandler = { (_, cgContext) in
            /// Change the background color temporarily in order to create a mask of the entire layer contents.
            self.usesProfileSpotButton.layer!.backgroundColor = NSColor.black.cgColor
            self.usesProfileSpotButton.layer!.render(in: cgContext)
            self.usesProfileSpotButton.layer!.backgroundColor = NSColor.clear.cgColor
        }

        /// The Markdown string we'll use for an additional stage (i.e. an additional message/description/whatever).
        let coolMarkdownString = """
            I also use a custom _profile spot_.
            <br>
            <img src='https://media.giphy.com/media/142K5KNLmUBtYI/giphy.gif' alt='Cool' height='100'>
            """
        /// Create a new stage with a specified preferred popover edge.
        let coolStage = EnlightenIrisStage(markdownString: coolMarkdownString, preferredPopoverEdge: .minX)
        coolStage.doesCenterAlignContent = true
        /// Add an additional "stage" or "step" for this iris' view.
        usesProfileSpotButtonIris.addAdditional(stage: coolStage)

        /// Since we initialized the keyed iris ourselves, the final step is adding it to the spotlight controller.
        keyedSpotlightController.addSpotlight(keyedIris: usesProfileSpotButtonIris)


        // MARK: Text View Iris

        /// The CommonMarkdown Markdown string we'll use for the text view iris.
        /// Note: This is HTML, which CommonMarkdown supports.
        let textViewMarkdown = """
            I'm an animated `NSTextView`.<br>
            I disable navigation until my animation completes.
            """
        /// For the text view, we'll use the keyed spotlight controller's convenience method that both creates and adds the keyed iris to the controller.
        /// Note: The convenience method returns the newly create iris, but for pedagogical reasons we'll ignore it.
        keyedSpotlightController.addSpotlight(presentationOrderKey: .textView,
                                              view: textView,
                                              markdownString: textViewMarkdown)

        /// You can retrieve an iris that was already added to the controller, like so.
        let textViewIris = keyedSpotlightController.keyedIris(for: textView)!
        /// Or even using its presentation order key.
//        let textViewIris = keyedSpotlightController.keyedIris(for: .textView)!
        /// The text view has a focus animation that takes a few seconds to complete, and we want to prevent any controller navigation until it finishes. Setting this property to true will disable any navigation until it finishes.
        textViewIris.doesWaitForFocusAnimationCompletion = true
        // Center align all the stages' Markdown content.
        textViewIris.doesCenterAlignContent = true

        /// An animated typer that simulates a human typing into the text view.
        let animatedTyper = AnimatedTyper(textView: textView, string: "How fun. 🎉")
        /// The irises are able to perform animations during the focusing and unfocusing of the spotlight on them. One way of specifying the animation groups is by providing the iris' `focusAnimationGroup` and `unfocusAnimationGroup` closures.
        ///
        /// This animation group will be called when the iris' view gains the spotlight focus.
        textViewIris.focusAnimationGroup = { context in
            context.duration = 4

            animatedTyper.start()
        }
        /// This animation group will be called when the iris' view looses the spotlight focus (i.e. unfocuses).
        textViewIris.unfocusAnimationGroup = { _ in
            animatedTyper.clear()
        }


        // MARK: `CustomView` Iris

        /// For the custom view, we'll use the keyed spotlight controller's convenience method that both creates and adds the keyed iris to the controller. Instead of directly using a Markdown string for this iris, we'll use the contents of a Markdown file in our main bundle.
        ///
        /// The `CustomView` conforms to the `EnlightenSpotlight` protocol, which is an additional way of configuring the iris. Instead of providing the iris itself with focus and unfocus animation groups—like we did above for the text view, the `CustomView` implements their respective protocol methods, namely `enlightenSpotlightFocusAnimation(using:)` and `enlightenSpotlightUnfocusAnimation(using:)`.
        ///
        /// Note: Since 'custom-view.md' is in our bundle, we can guarantee no reading errors.
        try! keyedSpotlightController.addSpotlight(presentationOrderKey: .customView,
                                                   view: customView,
                                                   markdownFilename: "custom-view",
                                                   in: Bundle.main)


        // MARK: Enlighten Help Button Iris

        /// Nothing special here.
        try! keyedSpotlightController.addSpotlight(presentationOrderKey: .enlightenHelpButton,
                                                   view: enlightenHelpButton,
                                                   markdownFilename: "enlighten-help-button",
                                                   in: Bundle.main)


        // MARK: 'Followspot Shape' Segmented Control Iris

        /// Or here.
        try! keyedSpotlightController.addSpotlight(presentationOrderKey: .followspotShapeSegmentedControl,
                                              view: followspotShapeSegmentedControl,
                                              markdownFilename: "followspot-shape-segmented-control",
                                              in: Bundle.main)


        // MARK: 'Present' Push Button Iris

        /// Even though this is the last iris we're adding to the controller, it will be the first one presented because it is the first enumeration case in our `SpotlightKey` enum—which specifies the presentation order.
        let presentButtonIris = try! keyedSpotlightController.addSpotlight(presentationOrderKey: .presentButton,
                                                                           view: presentButton,
                                                                           markdownFilename: "introduction",
                                                                           in: Bundle.main)
        /// Get the first stage of the iris.
        let introductionStage = presentButtonIris.stage(index: 1)!
        /// Make the stage center align its Markdown content.
        introductionStage.doesCenterAlignContent = true
        /// Set the stage's maximum width.
        introductionStage.popoverMaxWidth = 280
        /// Add two additional stages.
        presentButtonIris.addAdditionalStage(using: "You can skip me by pressing escape or mashing some keys. 🎹")
        presentButtonIris.addAdditionalStage(using: "Oh, & clicking on me will present the spotlight controller. 💡")

        // Finally, the controller also provides a method for validating the CommonMark Markdown stings, which should be done in test suites.
        do {
            try keyedSpotlightController.validateMarkdownStrings()
        } catch {
            print(error)
        }
    }

    func setupViews() {
        let visualEffectView = NSVisualEffectView(frame: view.frame)
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.autoresizingMask = [.height, .width]
        view.addSubview(visualEffectView, positioned: .below, relativeTo: nil)

        // Allow the help button's popover to detach.
        enlightenHelpButton.canDetachPopover = true
        // Set the popover delegate to ourself. The popover will notify the delegate (us) when/if the Markdown string fails to load, and when a Enlighten URL was clicked.
        enlightenHelpButton.enlightenPopoverDelegate = self
        // Set the Markdown string in the help button's popover.
        enlightenHelpButton.update(markdownString: helpButtonMainPageMarkdown)
        // The help button's tooltip Markdown content.
        let helpButtonToolTip = """
            # Need help?

            **This is a Markdown string**, stripped of any _styling_.
            """
        // You can use a Markdown string as a tool tip. The Markdown string will be stripped of any styling.
        // This can be useful if you want to use the same Markdown strings/files for the spotlight controller and tool tips.
        try! enlightenHelpButton.enlightenTooltip(markdownString: helpButtonToolTip)

        presentButton.target = self
        presentButton.action = #selector(startSpotlightOnboarding)

        // Sets the segmented control's labels.
        for (index, followspotShape) in EnlightenSpotlightController.FollowspotShape.allCases.enumerated() {
            followspotShapeSegmentedControl.setLabel(followspotShape.description, forSegment: index)
        }

        followspotShapeSegmentedControl.target = self
        followspotShapeSegmentedControl.action = #selector(segmentedControlAction)
        followspotShapeSegmentedControl.setSelected(true, forSegment: 1)

        textView.textColor = NSColor.textColor

        usesProfileSpotButton.wantsLayer = true
        // Does not change the button visually, but used when drawing the custom profile spot mask.
        usesProfileSpotButton.layer!.cornerRadius = 5
        usesProfileSpotButton.target = self
        usesProfileSpotButton.action = #selector(checkButtonAction)
    }

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupSpotlightController()
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        // IMPORTANT: Because we're using a `NSVisualEffectView` for the window background, we need to set the window's background color to clear. For some reason, CoreAnimation uses the window's background color during certain animations, like when animating a subview addition to the window's content view.
        view.window!.backgroundColor = .clear
        // Present the onboarding.
        keyedSpotlightController.present(animating: false)
    }
}

// MARK: - Enlighten Popover Delegate

// The `EnlightenPopoverDelegate` protocol is for the `EnlightenHelpButton`.
extension ViewController: EnlightenPopoverDelegate {
    func enlightenPopover(didClickEnlighten url: URL) {
        print("Clicked on url: \(url)")

        if let host = url.host, let page = HelpPage(rawValue: host) {
            switch page {
            case .mainPage:
                enlightenHelpButton.update(markdownString: helpButtonMainPageMarkdown)
            case .seeMorePage:
                enlightenHelpButton.update(markdownString: helpButtonSeeMorePageMarkdown)
            }
        }
    }

    func enlightenPopoverFailedToLoad(downError: Error) -> String? {
        print(#function, downError)
        return nil
    }
}

// MARK: - Enlighten Spotlight Controller Delegate

extension ViewController: EnlightenSpotlightControllerDelegate {
    func spotlightControllerWillShow(stage: Int,
                                     in iris: EnlightenIris,
                                     navigating: EnlightenSpotlightController.NavigationDirection) {
        guard let keyedIris = iris as? EnlightenKeyedIris<SpotlightKey>
            else { return }
        print("Navigating \(navigating) will show stage \(stage) in \(keyedIris.presentationOrderKey)")
    }

    func spotlightControllerDidDismiss() {
        print(#function)
    }

    func spotlightControllerFailedToLoad(markdownString: String, for iris: EnlightenIris, with error: Error) -> String? {
        print("""
            [Failed to load Markdown] Error: \(error)
            \"\(markdownString)\"
            """)
        return nil
    }
}

// MARK: - Action Methods

extension ViewController {
    /// The `presentButton`'s action method.
    ///
    /// It presents the spotlight-based onboarding.
    @objc
    func startSpotlightOnboarding() {
        keyedSpotlightController.present(animating: true)

        let usesProfileSpotButtonIris = keyedSpotlightController.keyedIris(for: .usesProfileSpotButton)!
        usesProfileSpotButtonIris.stages[0].markdownString = usesProfileSpotMarkdown
    }

    /// The `followspotShapeSegmentedControl`'s action method.
    @objc
    func segmentedControlAction() {
        let selectedSegmentShape = EnlightenSpotlightController.FollowspotShape
            .allCases[followspotShapeSegmentedControl.selectedSegment]
        keyedSpotlightController.followspotShape = selectedSegmentShape
    }

    /// The `usesProfileSpotButton`'s action method.
    @objc
    func checkButtonAction() {
        keyedSpotlightController.usesProfileSpot = usesProfileSpotButton.state == .on
    }
}

