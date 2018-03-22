# FeatherRESTClient
Sample project that demonstrates a lightweight REST client framework using protocols and generics.

## Top-down View
Before getting into the details of the implementation lets see how REST calls are made by the app. Try not to think too much about the UI implementation, it's simply a slight customization of Xcode's Master-Detail app template.

### signIn() - MasterViewController.swift
The `signIn()` method demonstrates a service call in its simplest form:
1. Start the activity spinner.
1. Instantiate the request data that is specific to the call we want to make (i.e. URL, headers, etc.).
1. Send the request.
1. Upon completion:
	1. Stop the activity spinner.
	1. Check for success or failure & act accordingly.
	
#### The Response - `authResponse`
* `authResponse` is of type `WebServiceResult<AuthenticationInfo>`
* An enum that includes `success` and `failure`
* Uses enum associated values to provide the respone data model, if success, and an error object for failure
* Uses generics to indicate the type of the response model data (`AuthenticationInfo`).
	
#### The Request Data - RequestDataForAuthenticate
In addition to the standard request information (path, headers, method), authentication requires a `userId` and `password`, which get applied to the request body as JSON.

### requestRandomJokes() - MasterViewController.swift
You can see the same pattern repeated - spinner, request data, send, handle response. The biggest difference is simply the actions taken upon success/failure.

#### `RequestDataForRandomJokes`
Notice that this takes someinput data as well, but this time it is added to the URL string as query parameters because this is a GET request.

### JsonWebService.sendRequest()
* Uses generics to indicate the response data model type, which implements the `Decodable` protocol enabling the model to be initialized from the JSON response.
* This implementation demonstrates how an authentication token can be refreshed before the data request is made.
* Uses a URLSession to make the actual request.

#### JsonWebService.handleRequestResponse()
* First does a bunch of error checking
* Then uses a `JSONDecoder` to initialize a response data model. This is surprisingly straight-forward.
	1. Define a data model that has property names which match the JSON response. (i.e. `JokeResponse`)
	1. Apply the `Decodable` (or `Codable`) protocol to the data model
	1. Instantiate using `JSONDecoder`

## Protocols & Dependency Injection
Protocols are used extensively in order to enable dependency injection.

### JsonWebServiceable - JsonWebServiceable.swift
This enables consumers to inject the JSON web service so that the consumer can be unit tested without making actual web calls.

### WebServiceable.swift
This file contains supporting protocols, structs and enums.

### Injectable Singleton - JsonWebService
`JsonWebService` uses the singleton pattern, which makes dependency injection a bit challenging. This is handled via `resetSharedInstance()`, which is called from `application(:, didFinishLaunchingWithOptions:)` because it must be called before `JsonWebService` is used.

This makes the logic in `JsonWebService` fully unit testable!

#### application(:, didFinishLaunchingWithOptions:) - AppDelegate.swift
A compiler flag (`USE_FAKES`) is used to indicate whether to use a real `URLSession` or a fake one. The compiler flag is associated with a build scheme making it quick and easy to generate builds that use fakes instead of the real thing.

## Unit Tests


## License

FeatherRESTClient is [MIT licensed](./LICENSE.md).