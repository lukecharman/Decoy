# Decoy

## ❓ So, what is Decoy?

Decoy is a pair of Swift packages used to easily create local, stubbed responses to network calls made
via `URLSession`. These are managed entirely within Xcode, and no HTTP server or other intermediary is required.
Using Decoy, you can:

* Queue specific stubbed JSON responses to requests to specific endpoint URLs.
* Return those stubbed responses in the order they were queued to create a flow.
* Use `URLSession` as normal in your app's features, meaning Decoy is not exposed to your features internally.

## 🧱 And how do I implement it?

`Decoy` and its sister package `DecoyXCUI` are added as dependencies of your `App` and its `AppUITests`
targets respectively. They're only a few kilobytes in size and will have no major impact on the size of your release
binary in the App Store. Decoy works best when your app uses a shared instance of `URLSession`, as in this case,
you only need `import Decoy` once. To get up and running:

### In the project:
* Add `Decoy` as a dependency of your app.
* Add `Decoy` and `DecoyXCUI` as dependencies of your UI test target.
  * Tap your app's project in the Project Navigator.
  * Under "Targets", tap your app's UI testing target.
  * Tap Build Phases.
  * Unfold the "Link Binary With Libraries" section.
  * Use the plus icon to add both `Decoy` and `Decoy+XCUI` to the list.
  * Ensure they are both assigned the 'Required' status.

### In the app:
* In your app, set up Decoy as soon as your app launches:
  ```
  Decoy.shared.setUp(session: Session())
  ```
* This will implicitly stub `URLSession.shared`, but you can pass in your own if you prefer.
* When you use `URLSession` in your app, use `Decoy.session` instead:
  ```
  ViewModel(urlSession: Decoy.shared.session as? URLSession ?? .shared)
  ```
  
### In the UI test target:
* In your UI test target, have the test classes inherit from `DecoyUITestCase`.
* Call the custom `setUp()` method, like so, passing in whether or not you'd like to record.
  ```
  override func setUp() {
    super.setUp(recording: false)
  }
  ```
* This will launch your app with the required environment variables to use Decoy.

## 🔴 Can I record with it?

Yes! One of Decoy' handier features is the ability to record real responses provided by your APIs, and then play
them back when running the tests. You can think of this similarly to how recording works in popular snapshot testing
libraries, where you'll record a "known good" state of your API, then not hit the real network when running your tests,
allowing your UI tests to be exactly that, rather than full integration tests.

*Note: One gap here that I hope to plug in future updates to Decoy is the ability to verify that the recorded
responses are still in line with those provided by the real backend, and some way to notify you if your backend has
changed and you're running tests against stubs which do not reflect the real API.*

### How to record:
* First, write your UI test using your real API. Ensure that it's reliable and passes.
* Once you're happy, ask Decoy to record it by changing your `setUp()` method, like so:
  ```
  override func setUp() {
    super.setUp(recording: true)
  }
  ```
* Now, run the test again.
* As the test progresses, each call to the network through your stubbed `URLSession` will now be captured.
* When the test completes, these are written to a `__Decoys__` directory in your UI tests target.
* They will be automatically titled with the name of the individual test case you were running, plus `.json`.

### How to play back:
* First, switch recording mode back off:
  ```
  override func setUp() {
    super.setUp(recording: false)
  }
  ```
* Now, re-run your tests.
* Decoy will detect that a stub exists with the given test name, and will pass it on to your app.

## 👩‍💻 Can I try it for myself?

There's a `DecoyExample` in this repository. You can build it and take a look, it's super simple. It uses a
free "random word" API as an example and its UI test target shows how to stub single or multiple calls to single or
multiple endpoints with Decoy.

## 💡 What are your future plans for Decoy?

It's still early days, and I'm excited to see how we can continue to grow Decoy into an even more useful UI
test stubbing library. It's a specific use case that I don't really want to deviate from too much, I'm thinking of
these tests as snapshots with a flow, and separate from integration testing (which is still crucially important).

Some specific things that still need doing / some ideas for the future:
* Decide on how errors are represented in the JSON and how to stub them usefully.
  * We need to think about Swift Errors vs. NSErrors vs. a JSON dictionary of error parameters, etc.
* Automatically generate stubs for an API using some sort of scripting and Swagger, etc.
* Verify recorded stubs are still up to date versus responses delivered from the backend they are stubbing.

